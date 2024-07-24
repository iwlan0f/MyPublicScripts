package main

//goOauth2Evokos
//this script is created to solve a problem with Evoko Room Manager device. oldest versions have been depracated because they have no support for Oauth2 microsoft exchange implementation.
//you can use https if you need, but you need to modify the code (should be very eazy with http.ListenAndServeTLS) and manually install tls certs on evoko room managers necessary path.
//made by iwlan0f

import (
	"bytes"
	"fmt"
	"io"
	"io/ioutil"
	"log"
	"net/http"
	"strings"
	"sync"
	"time"

	"golang.org/x/oauth2"
	"golang.org/x/oauth2/clientcredentials"
)

// create type to set settings
type Config struct {
	ClientID     string
	ClientSecret string
	TenantID     string
	EWSURL       string
	UserEmail    string
	Debug        bool
	Port         string
}

// set settings
var config = Config{
	ClientID:     "your client id",                                  //EntraID
	ClientSecret: "your client secret",                              //EntraID
	TenantID:     "your tenant",                                     //EntraID
	EWSURL:       "https://outlook.office365.com/EWS/Exchange.asmx", // Endpoint de EWS
	UserEmail:    "roomadmin@mail.local",                            // Room Administrator Email
	Debug:        true,                                              // Enable/Disable logs
	Port:         "8888",                                            // Server listening port.
}

// config 4 oauth2
var oauth2Config = clientcredentials.Config{
	ClientID:     config.ClientID,
	ClientSecret: config.ClientSecret,
	TokenURL:     fmt.Sprintf("https://login.microsoftonline.com/%s/oauth2/v2.0/token", config.TenantID),
	Scopes:       []string{"https://outlook.office365.com/.default"},
}

// lock sometimes because 1<evokoN
var tokenCache = struct {
	sync.Mutex
	token *oauth2.Token
}{}

// get client request, translate endpoint, do oauth2, add oauth header to client req, return server response.
func proxyRequest(w http.ResponseWriter, r *http.Request) {
	if config.Debug {
		log.Println("Handling request for:", r.URL.Path)
		logRequestDetails(r)
	}

	token := getTokenFromCacheOrFetch()
	if token == nil {
		if config.Debug {
			log.Println("Failed to obtain token")
		}
		http.Error(w, "Failed to obtain token", http.StatusUnauthorized)
		return
	}

	if config.Debug {
		log.Println("Using token:", token.AccessToken)
	}

	client := oauth2.NewClient(oauth2.NoContext, oauth2.StaticTokenSource(token))

	var proxyURL string
	if strings.HasPrefix(r.URL.Path, "/EWS/Exchange.asmx") {
		proxyURL = config.EWSURL
	} else {
		proxyURL = translateLegacyEndpoint(r.URL.Path)
	}

	if config.Debug {
		log.Println("Forwarding request to:", proxyURL)
	}

	req, err := http.NewRequest(r.Method, proxyURL, r.Body)
	if err != nil {
		if config.Debug {
			log.Printf("Failed to create request: %v", err)
		}
		http.Error(w, "Failed to create request: "+err.Error(), http.StatusInternalServerError)
		return
	}
	req.Header = r.Header
	req.Header.Set("Authorization", "Bearer "+token.AccessToken)

	if strings.HasPrefix(r.URL.Path, "/EWS/Exchange.asmx") {
		req, err = addExchangeImpersonationHeader(req, config.UserEmail)
		if err != nil {
			if config.Debug {
				log.Printf("Failed to add ExchangeImpersonation header: %v", err)
			}
			http.Error(w, "Failed to add ExchangeImpersonation header: "+err.Error(), http.StatusInternalServerError)
			return
		}
	}

	resp, err := client.Do(req)
	if err != nil {
		if config.Debug {
			log.Printf("Failed to perform request: %v", err)
		}
		http.Error(w, "Failed to perform request: "+err.Error(), http.StatusInternalServerError)
		return
	}
	defer resp.Body.Close()

	body, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		if config.Debug {
			log.Printf("Failed to read response body: %v", err)
		}
		http.Error(w, "Failed to read response body: "+err.Error(), http.StatusInternalServerError)
		return
	}

	if config.Debug {
		log.Printf("Response status: %v", resp.Status)
		log.Printf("Response body: %s", body)
	}

	for name, values := range resp.Header {
		for _, value := range values {
			w.Header().Add(name, value)
		}
	}

	w.WriteHeader(resp.StatusCode)
	w.Write(body)
}

// add headers to req
func addExchangeImpersonationHeader(req *http.Request, email string) (*http.Request, error) {
	body, err := ioutil.ReadAll(req.Body)
	if err != nil {
		return nil, err
	}
	req.Body.Close()

	soapHeader := fmt.Sprintf(`
        <t:ExchangeImpersonation xmlns:t="http://schemas.microsoft.com/exchange/services/2006/types">
            <t:ConnectingSID>
                <t:PrimarySmtpAddress>%s</t:PrimarySmtpAddress>
            </t:ConnectingSID>
        </t:ExchangeImpersonation>`, email)

	newBody := strings.Replace(string(body), "<soap:Header>", "<soap:Header>"+soapHeader, 1)

	req.Body = ioutil.NopCloser(bytes.NewReader([]byte(newBody)))
	return req, nil
}

// replace old endpoints
func translateLegacyEndpoint(path string) string {
	switch path {
	case "/legacy/endpoint1":
		return "https://graph.microsoft.com/v1.0/current/endpoint1"
	case "/legacy/endpoint2":
		return "https://graph.microsoft.com/v1.0/current/endpoint2"
	default:
		return "https://graph.microsoft.com/v1.0" + path
	}
}

// log (only if debug=true)
func logRequestDetails(r *http.Request) {
	log.Println("Request method:", r.Method)
	log.Println("Request URL:", r.URL.String())
	log.Println("Request headers:")
	for name, headers := range r.Header {
		for _, h := range headers {
			log.Printf("%v: %v", name, h)
		}
	}
	if r.Body != nil {
		bodyBytes, err := io.ReadAll(r.Body)
		if err == nil {
			log.Println("Request body:", string(bodyBytes))
			r.Body = ioutil.NopCloser(strings.NewReader(string(bodyBytes)))
		} else {
			log.Printf("Failed to read request body: %v", err)
		}
	}
}

// obtain accessToken oauth
func getTokenFromCacheOrFetch() *oauth2.Token {
	tokenCache.Lock()
	defer tokenCache.Unlock()

	if tokenCache.token == nil || tokenCache.token.Expiry.Before(time.Now().Add(30*time.Second)) {
		if config.Debug {
			log.Println("Token is nil or expired, fetching new token")
		}
		token, err := oauth2Config.Token(oauth2.NoContext)
		if err != nil {
			if config.Debug {
				log.Printf("Failed to fetch token: %v", err)
			}
			return nil
		}
		tokenCache.token = token
	} else {
		if config.Debug {
			log.Println("Using cached token")
		}
	}
	return tokenCache.token
}

// starting...
func main() {
	http.HandleFunc("/", proxyRequest)
	if config.Debug {
		log.Println("Server is running at", config.Port)
	}
	log.Fatal(http.ListenAndServe(":"+config.Port, nil))
}

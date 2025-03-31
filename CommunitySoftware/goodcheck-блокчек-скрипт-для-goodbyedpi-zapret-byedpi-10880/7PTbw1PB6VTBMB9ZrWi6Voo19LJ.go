package main

import (
	"bufio"
	"fmt"
	"net/http"
	"net/http/httptrace"
	"os"
	"os/exec"
	"strings"
	"time"
)

var connTimeout int = 2

const (
	//Folders for Checker
	checklistsFolder = "Checklists"
	checklist        = "default - all.txt"

	strategiesFolder = "Strategies"
	strategiesyList  = "[basic functionality test].txt"

	//Folders for program
	gdpiName    = "GoodbyeDPI"
	gdpiExeName = "goodbyedpi.exe"
	gdpiFolder  = "D:/Soft/_Portable/goodbyedpi-0.2.3rc1/x86_64"

	//Strategy-related
	fakeSni    = "www.google.com"
	fakeHexRaw = "1603030135010001310303424143facf5c983ac8ff20b819cfd634cbf5143c0005b2b8b142a6cd335012c220008969b6b387683dedb4114d466ca90be3212b2bde0c4f56261a9801"
)

var _successes int

func init() { _successes = 0 }

func main() {

	var _strategies []string = readStrategies(strategiesFolder + string(os.PathSeparator) + gdpiName + string(os.PathSeparator) + strategiesyList)
	var _totalStrategies = len(_strategies)

	var _urls []string = readURLs(checklistsFolder + "/" + checklist)
	var _totalSites = len(_urls)

	for i := 1; i < _totalStrategies; i++ {

		fmt.Println("Checking strategy:", _strategies[i])
		fmt.Println("Starting program...")
		_program := exec.Command(`./x86_64/goodbyedpi.exe`, `_strategies[i]`)
		err := _program.Start()
		fmt.Println("Status:", err)

		time.Sleep(1 * time.Second)

		fmt.Println("Making request...")
		sendRequests(_urls)
		time.Sleep(2 * time.Second)

		fmt.Println("Terminating program...")
		_program.Process.Kill()
		time.Sleep(1 * time.Second)

		fmt.Println("Strategy", i, "/", _totalStrategies, "	Successes: ", _successes, "/", _totalSites)
		_successes = 0
	}

}

func readURLs(_filename string) []string {

	_file, _error := os.Open(_filename)
	check(_error)
	defer _file.Close()

	var _lines []string
	_scanner := bufio.NewScanner(_file)

	for _scanner.Scan() {
		if !isCommented(_scanner.Text(), "/") {
			var _line string = cleanURL(_scanner.Text())
			fmt.Println("Site to check:", _line)
			_lines = append(_lines, _line)
		}
	}
	check(_error)

	return _lines
}

func readStrategies(_filename string) []string {

	_file, _error := os.Open(_filename)
	check(_error)
	defer _file.Close()

	var _lines []string
	_scanner := bufio.NewScanner(_file)

	for _scanner.Scan() {
		if !isCommented(_scanner.Text(), "/") && !isCommented(_scanner.Text(), "_") {
			_replacer := strings.NewReplacer("FAKEHEX", fakeHexRaw, "FAKESNI", fakeSni)
			var _strategy = _replacer.Replace(_scanner.Text())
			fmt.Println("Strategy found:", _strategy)
			_lines = append(_lines, _strategy)
		}
	}
	check(_error)

	return _lines
}

func cleanURL(_url string) string {
	_replacer := strings.NewReplacer("http://", "", "https://", "")
	var _cleanedUrl = _replacer.Replace(_url)

	_cleanedUrl = "https://" + _cleanedUrl
	return _cleanedUrl
}

func isCommented(_line string, _symbol string) bool {
	return string(_line[0]) == _symbol
}

func sendRequests(_urls []string) {

	//wg := sync.WaitGroup{}

	for _, _url := range _urls {
		//wg.Add(1)
		//go sendRequest(&wg, _url)
		go sendRequest(_url)
	}

	//wg.Wait()

}

// func sendRequest(wg *sync.WaitGroup, _url string) {
// defer wg.Done()
func sendRequest(_url string) {

	var _code int = 0
	var _ip string = "unknown"

	_request, _requestError := http.NewRequest("GET", _url, nil)
	if _requestError != nil {
		//fmt.Println("URL:", _url, "IP:", _ip, "CODE:", _code)
		//_request.Body.Close()
		return
	}

	_trace := &httptrace.ClientTrace{
		GotConn: func(connInfo httptrace.GotConnInfo) {
			_ip = connInfo.Conn.RemoteAddr().String()
		},
	}
	_request = _request.WithContext(httptrace.WithClientTrace(_request.Context(), _trace))

	_transport := &http.Transport{
		MaxIdleConns:       300,
		IdleConnTimeout:    2 * time.Second,
		DisableCompression: true,
	}
	_client := &http.Client{Transport: _transport}
	//_client := &http.Client{}

	_response, _responseError := _client.Do(_request)
	if _responseError != nil {
		//fmt.Println("URL:", _url, "IP:", _ip, "CODE:", _code)
		//_response.Body.Close()
		return
	}

	_code = _response.StatusCode

	fmt.Println("URL:", _url, "IP:", _ip, "CODE:", _code)

	_successes++

}

func check(_error error) {
	if _error != nil {
		panic(_error)
	}
}

package main

import (
	"bufio"
	"fmt"
	"net/http"
	"net/http/httptrace"
	"os"
	"os/exec"
	"strings"
	"sync"
	"syscall"
	"time"
)

type Strategy struct {
	ID           int
	StrategyKeys string
	Successes    int
}

func newStrategy(StrategyKeys string, ID int) *Strategy {
	s := Strategy{
		ID:           ID,
		StrategyKeys: StrategyKeys,
		Successes:    0,
	}
	return &s
}

type SiteToCheck struct {
	ID           int
	WebAddress   string
	IP           string
	ResponseCode int
}

func newSiteToCkeck(WebAddress string, ID int) *SiteToCheck {
	s := SiteToCheck{
		ID:           ID,
		WebAddress:   WebAddress,
		IP:           "unknown",
		ResponseCode: 0,
	}
	return &s
}

type FoolingProgram struct {
	name           string
	executableName string
	path           string
	serviceName    string
}

func newFoolingProgram(name string, executableName string, path string, serviceName string) *FoolingProgram {
	p := FoolingProgram{
		name:           name,
		executableName: executableName,
		path:           path,
		serviceName:    serviceName,
	}
	return &p
}

const (
	configFileName = "config.ini"
)

var connTimeout int = 2
var sitesToCheck []SiteToCheck
var strategies []Strategy
var curlExtraKeys string
var gdpi FoolingProgram
var checklistsFolder string
var checklist string
var strategiesFolder string
var strategiesList string
var fakeSni string
var fakeHexRaw string

func init() {
	//Main folders and files
	checklistsFolder = lookForptionInConfig(configFileName, "ChecklistsFolder")
	checklist = lookForptionInConfig(configFileName, "Checklist")
	strategiesFolder = lookForptionInConfig(configFileName, "StrategiesFolder")
	strategiesList = lookForptionInConfig(configFileName, "StrategiesList")

	//Common fooling options
	fakeSni = lookForptionInConfig(configFileName, "FakeSni")
	fakeHexRaw = lookForptionInConfig(configFileName, "FakeHexRaw")

	//GoodbyeDPI
	gdpi = lookForProgramOptionsInConfig(configFileName, "GdpiName", "GdpiExecutable", "GdpiPath", "GdpiServiceName")

	//Processing checklist
	fmt.Println(checklistsFolder, checklist)
	sitesToCheck = readChecklistFile(checklistsFolder + string(os.PathSeparator) + checklist)

	//Processing strategies list
	strategies, curlExtraKeys = readStrategiesFile(strategiesFolder + string(os.PathSeparator) + gdpi.name + string(os.PathSeparator) + strategiesList)
	fmt.Println("Curl extra keys:", curlExtraKeys)
}

func main() {

	for i := 0; i < len(strategies); i++ {

		fmt.Println("Checking strategy:", strategies[i].StrategyKeys)
		fmt.Println("Starting program...")
		_program := exec.Command(gdpi.path + string(os.PathSeparator) + gdpi.executableName)
		_program.SysProcAttr = &syscall.SysProcAttr{CmdLine: " " + strategies[i].StrategyKeys}
		//_program := exec.Command("cmd.exe")
		//_program.SysProcAttr = &syscall.SysProcAttr{CmdLine: "/c start " + gdpiFolder + string(os.PathSeparator) + gdpiExeName + " " + _strategies[i]}

		err := _program.Start()
		check(err, "Error when starting the program:")

		time.Sleep(1 * time.Second)

		fmt.Println("Making requests...")
		sendRequests(sitesToCheck)

		fmt.Println("Showing results...")
		successes := 0
		for _, site := range sitesToCheck {
			fmt.Println("URL:", site.WebAddress, "IP:", site.IP, "CODE:", site.ResponseCode, http.StatusText(site.ResponseCode))
			if site.ResponseCode != 0 {
				successes++
			}
		}
		fmt.Println("Successes:", successes, "/", len(sitesToCheck))
		strategies[i].Successes = successes

		fmt.Println("Terminating program...")
		err = _program.Process.Kill()
		check(err, "Error when terminating the program:")
	}

	fmt.Println("All strategies tested, showing results")
	total := len(sitesToCheck)
	for j := 0; j <= total; j++ {
		var lines []string
		for _, strategy := range strategies {
			if strategy.Successes == j {
				lines = append(lines, strategy.StrategyKeys)
			}
		}
		if lines != nil {
			fmt.Println("Strategies with", j, "/", total, "successes:")
			for _, line := range lines {
				fmt.Println(line)
			}
		}

	}

	fmt.Println("All tasks completed")
	fmt.Scanln()
}

func lookForptionInConfig(config string, option string) string {
	f, err := os.Open(config)
	check(err, "Error when opening a config file")
	defer f.Close()

	scan := bufio.NewScanner(f)
	for scan.Scan() {
		if !isCommented(scan.Text(), "[") && !isCommented(scan.Text(), "/") {
			param := strings.Split(scan.Text(), `=`)
			if param[0] == option {
				return param[1]
			}
		}
	}
	return "Error"
}

func lookForProgramOptionsInConfig(config string, programName string, programExecutable string, programPath string, programServiceName string) FoolingProgram {
	f, err := os.Open(config)
	check(err, "Error when opening a config file")
	defer f.Close()

	var program FoolingProgram
	scan := bufio.NewScanner(f)

	for scan.Scan() {
		if !isCommented(scan.Text(), "[") && !isCommented(scan.Text(), "/") {
			param := strings.Split(scan.Text(), `=`)
			switch param[0] {
			case programName:
				program.name = param[1]
			case programExecutable:
				program.executableName = param[1]
			case programPath:
				program.path = param[1]
			case programServiceName:
				program.serviceName = param[1]
			}
		}
	}
	return program
}

func readChecklistFile(filename string) []SiteToCheck {
	f, err := os.Open(filename)
	check(err, "Error when opening a checklist")
	defer f.Close()

	var sites []SiteToCheck
	scan := bufio.NewScanner(f)

	i := 0
	for scan.Scan() {
		if !isCommented(scan.Text(), "/") {
			site := cleanURL(scan.Text())
			fmt.Println("Site to check:", site)
			sites = append(sites, *newSiteToCkeck(site, i))
			i++
		}
	}
	return sites
}

func readStrategiesFile(filename string) ([]Strategy, string) {
	f, err := os.Open(filename)
	check(err, "Error when opening a strategy list")
	defer f.Close()

	var strategies []Strategy

	scan := bufio.NewScanner(f)
	linesCount := 0
	strategyExtraKeys := ""
	curlExtraKeys := ""
	i := 0
	for scan.Scan() {
		if !isCommented(scan.Text(), "/") {
			linesCount++
			if linesCount <= 2 {
				param := strings.Split(scan.Text(), `#`)
				if param[0] == "_strategyExtraKeys" {
					strategyExtraKeys = param[1]
				}
				if param[0] == "_strategyCurlExtraKeys" {
					curlExtraKeys = param[1]
				}
			} else {
				replacer := strings.NewReplacer("FAKEHEX", fakeHexRaw, "FAKESNI", fakeSni)
				strategyWithReplaces := replacer.Replace(scan.Text())
				fmt.Println("Strategy found:", strategyExtraKeys+" "+strategyWithReplaces)
				strategies = append(strategies, *newStrategy(strategyExtraKeys+" "+strategyWithReplaces, i))
				i++
			}
		}
	}
	return strategies, curlExtraKeys
}

func cleanURL(url string) string {
	replacer := strings.NewReplacer("http://", "", "https://", "")
	cleanedUrl := replacer.Replace(url)

	cleanedUrl = strings.Split(cleanedUrl, `/`)[0]

	cleanedUrl = "https://" + cleanedUrl

	return cleanedUrl
}

func isCommented(line string, symbol string) bool {
	if line != "" {
		return string(line[0]) == symbol
	}
	return true
}

func sendRequests(sites []SiteToCheck) {

	wg := sync.WaitGroup{}

	for _, site := range sites {
		wg.Add(1)
		go sendRequest(&wg, site)
	}

	wg.Wait()

}

func sendRequest(wg *sync.WaitGroup, site SiteToCheck) {
	defer wg.Done()

	_request, _requestError := http.NewRequest("GET", site.WebAddress, nil)
	if _requestError != nil {
		sitesToCheck[site.ID].ResponseCode = 0
		//_request.Body.Close()
		return
	}

	_trace := &httptrace.ClientTrace{
		GotConn: func(connInfo httptrace.GotConnInfo) {
			sitesToCheck[site.ID].IP = connInfo.Conn.RemoteAddr().String()
		},
	}
	_request = _request.WithContext(httptrace.WithClientTrace(_request.Context(), _trace))

	// _transport := &http.Transport{
	// 	MaxIdleConns:       300,
	// 	IdleConnTimeout:    5 * time.Second,
	// 	DisableCompression: true,
	// }
	_client := &http.Client{
		//Transport: _transport,
		Timeout: time.Duration(connTimeout) * time.Second,
	}

	_response, _responseError := _client.Do(_request)
	if _responseError != nil {
		sitesToCheck[site.ID].ResponseCode = 0
		//_response.Body.Close()
		return
	}

	sitesToCheck[site.ID].ResponseCode = _response.StatusCode
}

func check(_error error, _message string) {
	if _error != nil {
		fmt.Println(_message+":", _error)
		fmt.Scanln()
		panic(_error)
	}
}

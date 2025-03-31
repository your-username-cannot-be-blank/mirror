//by Ori

package main

import (
	"bufio"
	"fmt"
	"log"
	"net/http"
	"net/http/httptrace"
	"os"
	"os/exec"
	"strconv"
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
	version        = "0.1"
	configFileName = "config.ini"
)

var logsFolder string
var startT time.Time

var strategiesFolder string
var strategiesList string
var strategies []Strategy

var checklistsFolder string
var checklist string
var sitesToCheck []SiteToCheck

var connTimeout int
var curlExtraKeys string

var fakeSni string
var fakeHexRaw string

var gdpi FoolingProgram

func init() {
	//Main folders and files
	logsFolder = lookForOptionInConfig(configFileName, "LogsFolder")
	checklistsFolder = lookForOptionInConfig(configFileName, "ChecklistsFolder")
	checklist = lookForOptionInConfig(configFileName, "Checklist")
	strategiesFolder = lookForOptionInConfig(configFileName, "StrategiesFolder")
	strategiesList = lookForOptionInConfig(configFileName, "StrategiesList")

	//Variables
	var err error
	connTimeout, err = strconv.Atoi(lookForOptionInConfig(configFileName, "ConnTimeout"))
	check(err, "Error when reading ConnTimeout from config")

	//Removing logfile
	log.SetFlags(0)
	os.Remove(logsFolder + string(os.PathSeparator) + "logfile.log")
	startT = time.Now()
	writeToLog("Started at " + startT.String())

	//Common fooling options
	fakeSni = lookForOptionInConfig(configFileName, "FakeSni")
	fakeHexRaw = lookForOptionInConfig(configFileName, "FakeHexRaw")

	//GoodbyeDPI
	gdpi = *newFoolingProgram(
		lookForOptionInConfig(configFileName, "GdpiName"),
		lookForOptionInConfig(configFileName, "GdpiExecutable"),
		lookForOptionInConfig(configFileName, "GdpiPath"),
		lookForOptionInConfig(configFileName, "GdpiServiceName"),
	)

	//Processing checklist
	sitesToCheck = readChecklistFile(checklistsFolder + string(os.PathSeparator) + checklist)

	//Processing strategies list
	strategies, curlExtraKeys = readStrategiesFile(strategiesFolder + string(os.PathSeparator) + gdpi.name + string(os.PathSeparator) + strategiesList)
	writeToLog("Curl extra keys:" + curlExtraKeys)
}

func main() {
	totalStrategies := len(strategies)
	for i := 0; i < totalStrategies; i++ {

		writeToLog("Checking strategy (" + strconv.Itoa(i) + "/" + strconv.Itoa(totalStrategies) + "): " + strategies[i].StrategyKeys)
		writeToLog("Starting program...")
		_program := exec.Command(gdpi.path + string(os.PathSeparator) + gdpi.executableName)
		_program.SysProcAttr = &syscall.SysProcAttr{CmdLine: " " + strategies[i].StrategyKeys}
		//_program := exec.Command("cmd.exe")
		//_program.SysProcAttr = &syscall.SysProcAttr{CmdLine: "/c start " + gdpiFolder + string(os.PathSeparator) + gdpiExeName + " " + _strategies[i]}

		err := _program.Start()
		check(err, "Error when starting the program")

		//time.Sleep(1 * time.Second)

		writeToLog("Making requests...")
		sendRequests(sitesToCheck)

		writeToLog("Showing results...")
		successes := 0
		for _, site := range sitesToCheck {
			writeToLog("URL: " + site.WebAddress + " | IP: " + site.IP + " | CODE: " + strconv.Itoa(site.ResponseCode) + " " + http.StatusText(site.ResponseCode))
			if site.ResponseCode != 0 {
				successes++
			}
		}
		writeToLog("Successes:" + strconv.Itoa(successes) + "/" + strconv.Itoa(len(sitesToCheck)))
		strategies[i].Successes = successes

		writeToLog("Terminating program...")
		err = _program.Process.Kill()
		check(err, "Error when terminating the program")
	}

	writeToLog("All strategies tested, showing results")
	total := len(sitesToCheck)
	for j := 0; j <= total; j++ {
		var lines []string
		for _, strategy := range strategies {
			if strategy.Successes == j {
				lines = append(lines, strategy.StrategyKeys)
			}
		}
		if lines != nil {
			writeToLog("Strategies with " + strconv.Itoa(j) + "/" + strconv.Itoa(total) + " successes:")
			for _, line := range lines {
				writeToLog(line)
			}
		}

	}

	endT := time.Now()
	writeToLog("Ended at " + endT.String())
	writeToLog("Total time taken: " + endT.Sub(startT).String())
	writeToLog("All tasks completed")
	fmt.Scanln()
}

func lookForOptionInConfig(config string, option string) string {
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
			writeToLog("Site to check: " + site)
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
					if strategyExtraKeys != "" {
						strategyExtraKeys = strategyExtraKeys + " "
					}
				}
				if param[0] == "_strategyCurlExtraKeys" {
					curlExtraKeys = param[1]
					if curlExtraKeys != "" {
						curlExtraKeys = curlExtraKeys + " "
					}
				}
			} else {
				replacer := strings.NewReplacer("FAKEHEX", fakeHexRaw, "FAKESNI", fakeSni)
				strategyWithReplaces := replacer.Replace(strategyExtraKeys + scan.Text())
				writeToLog("Strategy found: " + strategyWithReplaces)
				strategies = append(strategies, *newStrategy(strategyWithReplaces, i))
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

func writeToLog(text string) {
	l, err := os.OpenFile(logsFolder+string(os.PathSeparator)+"logfile.log", os.O_RDWR|os.O_CREATE|os.O_APPEND, 0666)
	if err != nil {
		fmt.Println("Error opening a logfile:", err)
		fmt.Scanln()
		panic(err)
	}

	defer l.Close()

	fmt.Println(text)

	log.SetOutput(l)
	log.Println(text)
}

func check(_error error, _message string) {
	if _error != nil {
		writeToLog(_message + ": " + _error.Error())
		fmt.Scanln()
		panic(_error)
	}
}

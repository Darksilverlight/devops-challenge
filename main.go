package main

import (
	"devops-challange/internal/controllers"
	"flag"
	"log"
	"net/http"
	"os"
	"strconv"
	"time"

	"github.com/gorilla/mux"
)

func main() {
	port := flag.String("port", "", "Port to start app on. Will defualt to env port if not present. if env port is not present will defualt to 8000")

	if *port == "" || isInt(*port) {
		if temp, found := os.LookupEnv("PORT"); found && isInt(temp) {
			port = &temp
		} else {
			temp = "8000"
			port = &temp
		}
	}

	r := mux.NewRouter()

	r.HandleFunc("/", controllers.BasicHandler)
	r.HandleFunc("/health", controllers.HealthCheck)

	srv := &http.Server{
		Handler:      r,
		Addr:         ":" + *port,
		WriteTimeout: 15 * time.Second,
		ReadTimeout:  15 * time.Second,
	}
	log.Printf("app starting on port: %s", *port)
	log.Fatal(srv.ListenAndServe())
}

func isInt(value string) bool {
	_, err := strconv.Atoi(value)
	return err != nil
}

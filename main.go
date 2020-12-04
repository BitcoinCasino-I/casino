package main

import (
	"html/template"
	"log"
	"net/http"
)

func main() {
	http.Handle("/static/", http.StripPrefix("/static/", http.FileServer(http.Dir("static/"))))

	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		tmpl := template.Must(template.ParseFiles("templates/main.html"))
		tmpl.Execute(w, nil)
	})

	log.Fatal(http.ListenAndServe(":9990", nil))
}

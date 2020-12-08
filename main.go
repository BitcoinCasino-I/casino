package main

import (
	"html/template"
	"log"
	"net/http"
)

func main() {
	http.Handle("/assets/", http.StripPrefix("/assets/", http.FileServer(http.Dir("assets/"))))

	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		tmpl := template.Must(template.ParseFiles("templates/master.html"))
		tmpl.Execute(w, nil)
	})

	log.Fatal(http.ListenAndServe(":9990", nil))
}

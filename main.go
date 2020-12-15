package main

import (
	"fmt"
	"html/template"
	"log"
	"net/http"

	"github.com/gorilla/mux"
)

func main() {

	r := mux.NewRouter()

	r.PathPrefix("/assets/").Handler(http.StripPrefix("/assets/", http.FileServer(http.Dir("assets/"))))
	r.PathPrefix("/favicon_io/").Handler(http.StripPrefix("/favicon_io/", http.FileServer(http.Dir("favicon_io/"))))
	r.HandleFunc("/{html}", func(w http.ResponseWriter, r *http.Request) {
		vars := mux.Vars(r)
		if vars["html"] == "favicon.ico" {
			http.Redirect(w, r, "/favicon_io/favicon.ico", 308)
			return
		}

		file, err := template.ParseFiles(fmt.Sprintf("html/%s.html", vars["html"]))
		if err != nil {
			w.WriteHeader(404)
			return
		}
		tmpl := template.Must(file, nil)
		tmpl.Execute(w, nil)
	})

	r.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		tmpl := template.Must(template.ParseFiles("html/master.html"))
		tmpl.Execute(w, nil)
	})

	r.HandleFunc("/ajax/", func(w http.ResponseWriter, r *http.Request) {
		w.Write([]byte("Hello World"))
	})

	log.Fatal(http.ListenAndServe(":9990", r))
}

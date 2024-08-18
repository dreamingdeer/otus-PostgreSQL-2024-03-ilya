package main

import (
	"context"
	"fmt"
	"log"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/spf13/viper"
)

var tic int

func isEmpty(s string, name string) {
	if len(s) < 1 {
		log.Fatal(name, " unset")
	}
}

func main() {
	// get secrets from .env file
	// Внимание гавнокод )
	// на основе модуля https://github.com/jackc/pgx/wiki/Getting-started-with-pgx

	viper.SetConfigName(".env")
	viper.SetConfigType("dotenv")
	viper.AddConfigPath(".")
	err := viper.ReadInConfig()
	if err != nil {
		panic(fmt.Errorf("fatal error config file: %w", err))
	}

	delay := viper.GetInt("LOOP_DELAY")
	if delay == 0 {
		delay = 10
	}
	pguser := viper.GetString("PG_USER")
	isEmpty(pguser, "pguser")
	pgpass := viper.GetString("PG_PASSWORD")
	isEmpty(pgpass, "pgpass")
	pghost := viper.GetString("PG_HOST")
	isEmpty(pghost, "pghost")
	pgssl := viper.GetString("PG_SSLMODE")
	if len(pgssl) == 0 {
		pgssl = "disable"
	}
	pgdb := viper.GetString("PG_DB")
	if len(pgdb) == 0 {
		pgdb = "postgres"
	}
	pgport := viper.GetString("PG_PORT")
	if len(pgport) == 0 {
		pgport = "5432"
	}

	tic = 0

	// обработка ctrl+c
	c := make(chan os.Signal, 1)
	signal.Notify(c, os.Interrupt, syscall.SIGTERM)
	go func() {
		<-c
		log.Println("Loop count: ", tic)
		os.Exit(1)
	}()

	// pool watch for connection and reconnect
	connStr := "postgresql://" + pguser + ":" + pgpass + "@" + pghost + ":" + pgport + "/" + pgdb + "?sslmode=" + pgssl
	conn, err := pgxpool.New(context.Background(), connStr)
	if err != nil {
		log.Printf("Unable to create connection pool: %v\n", err)
		return
	}

	log.Println("Create connection pool to", pghost, "as", pguser)
	defer conn.Close()

	for {
		time.Sleep(time.Duration(delay) * time.Second)
		tic += 1

		var recovery bool
		err := conn.QueryRow(context.Background(), "SELECT pg_is_in_recovery()").Scan(&recovery)
		if err != nil {
			log.Printf("QueryRow failed: %v\n", err)
			continue
		}

		if recovery {
			log.Println("PG is in recovery process")
		} else {
			log.Print("PG is master")
		}
	}
}

#!/bin/bash
.PHONY: default
.SILENT:

default:


start: 
	docker-compose up -d 

stop:
	docker-compose down

build:
	docker-compose build

shell: 
	docker-compose exec jupyter bash

server-pso:
	ssh -i mestrado.pem ubuntu@ec2-3-82-59-223.compute-1.amazonaws.com

server-evol:
	ssh -i mestrado.pem ubuntu@ec2-54-80-100-71.compute-1.amazonaws.com

link:
	docker-compose exec jupyter jupyter notebook list

rm-untitled:
	rm work/Untitled*

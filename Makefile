# Build deliveroo-engineering blog
build:
	  @echo Building deliveroo-engineering
	  docker build -t deliveroo-engineering .

run:
	  @echo Starting jekyll server on port 4000
	  docker run -p 4000:4000 -v $(shell pwd):/usr/src/app/deliveroo.engineering deliveroo-engineering

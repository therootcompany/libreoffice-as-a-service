IMAGE=saas

run:
	docker run --rm -it -p 5227:5227 $(IMAGE)

build:
	docker build -t $(IMAGE) .

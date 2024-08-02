build:
	docker build --tag devops-challange .

dive:
	CI=true dive devops-challange

build-and-dive: build dive
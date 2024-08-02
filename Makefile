build:
	docker build --tag devops-challenge:local .

dive:
	CI=true dive devops-challenge:local

build-and-dive: build dive

ingress-controller-up:
	helm upgrade --install ingress-nginx ingress-nginx \
  --repo https://kubernetes.github.io/ingress-nginx \
  --namespace ingress-nginx --create-namespace\

ingress-controller-down:
	helm uninstall --ignore-not-found ingress-nginx --namespace ingress-nginx

load: 
	kind load docker-image devops-challenge:local

build-and-load: build load

deploy:
	helm upgrade --install devops-challenge ./devops-challenge-chart

build-load-and-deploy: build-and-load deploy

clean:
	helm uninstall --ignore-not-found devops-challenge ./devops-challenge-chart

clean-build-and-deploy: clean build-load-and-deploy

port-foward-up: 
	kubectl port-forward --namespace=ingress-nginx service/ingress-nginx-controller 8080:80

template:
	helm template devops-challenge-chart


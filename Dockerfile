FROM golang:1.22-alpine AS builder

#to prevent security scans from being mad and grab certs for scratch
RUN apk update && apk upgrade && \
    apk add --no-cache ca-certificates && \
    update-ca-certificates

## Create a custom user 
RUN addgroup --gid 1001 appgroup && \
adduser --disabled-password --uid 1001 --ingroup appgroup appuser
USER appuser
WORKDIR /app

#create a diffrent layer for dependencies
COPY go.mod go.sum /app/
RUN go mod download

#build with static linking so artifact can run on scratch
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o main .

#use scratch for smaller docker image size
FROM scratch AS runner
COPY --from=builder /etc/passwd /etc/passwd
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=builder /app/main .
USER appuser
ENTRYPOINT ["./main"]







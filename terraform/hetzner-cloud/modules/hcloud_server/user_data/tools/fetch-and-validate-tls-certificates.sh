#!/usr/bin/env bash
##################################################################################################################
# We use certbot with the route53 plugin with scoped down AWS credentials to validate our TLS certificates
# Certbot queries letsencrypt for a certificate and then adds a TXT Record to the AWS hosted zone's for validation
# certbot sets up automatic renewal and by default certificates are valid for only 90 days.
# PARAM $1 is the domain or subdomnain for tls certificate
# PARAM $2 optional second domain to fetch and validate. e.g. the demo instance uses two separate certs.
##################################################################################################################

if [[ -z "$1" ]] then
    echo "Error: Missing required parameters."
    echo "Usage: $0 <DOMAIN_NAME>"
    exit 1
fi

echo "Installing certbot and route53 dns plugin"
sudo dnf install --quiet -y certbot python3-certbot-dns-route53

if [[ "$2" ]] then
    echo "Requesting two tls certificates for"
    echo $1 && echo $2
    sudo certbot certonly \
    --dns-route53 \
    --non-interactive \
    --agree-tos \
    --key-type ecdsa \
    -d $1 \
    -d $2
else
    echo "Requesting single tls certificate for $1"
    sudo certbot certonly \
    --dns-route53 \
    --non-interactive \
    --agree-tos \
    --key-type ecdsa \
    -d $1
fi

# list generated certificates
echo "Listing created certificates"
sudo certbot certificates

# simulate certificate renewal
echo "Simulating certificate renewal"
sudo certbot renew --dry-run

### DEBUG ###
# Show decoded certificate content
# openssl x509 -in /etc/letsencrypt/live/demo.fiscalismia.com/fullchain.pem -text -noout
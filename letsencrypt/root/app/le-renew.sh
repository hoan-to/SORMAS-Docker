#!/usr/bin/with-contenv bash

if [ -n "${DISABLE_CERTBOT}" ];then
  exit 0
fi

. /config/donoteditthisfile.conf

echo "<------------------------------------------------->"
echo
echo "<------------------------------------------------->"
echo "cronjob running on "$(date)
echo "Running certbot renew"
if [ "$ORIGVALIDATION" = "dns" ] || [ "$ORIGVALIDATION" = "duckdns" ]; then
  certbot -n renew \
    --post-hook "if ps aux | grep [n]ginx: > /dev/null; then s6-svc -h /var/run/s6/services/nginx; fi; \
    cd /config/keys/letsencrypt && \
    openssl pkcs12 -export -out privkey.pfx -inkey privkey.pem -in cert.pem -certfile chain.pem -passout pass: && \
    sleep 1 && \
    cat privkey.pem fullchain.pem > priv-fullchain-bundle.pem"
else
  certbot -n renew \
    --pre-hook "if ps aux | grep [n]ginx: > /dev/null; then s6-svc -d /var/run/s6/services/nginx; fi" \
    --post-hook "if ps aux | grep 's6-supervise nginx' | grep -v grep > /dev/null; then s6-svc -u /var/run/s6/services/nginx; fi; \
    cd /config/keys/letsencrypt && \
    openssl pkcs12 -export -out privkey.pfx -inkey privkey.pem -in cert.pem -certfile chain.pem -passout pass: && \
    sleep 1 && \
    cat privkey.pem fullchain.pem > priv-fullchain-bundle.pem"
fi
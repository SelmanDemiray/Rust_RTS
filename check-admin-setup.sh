#!/bin/bash
# Script to check and diagnose admin page routing issues

echo "Checking client container setup..."
CLIENT_CONTAINER=$(docker ps | grep rts.*client | awk '{print $1}')

if [ -z "$CLIENT_CONTAINER" ]; then
  echo "Client container not found. Make sure it's running."
  exit 1
fi

echo "Found client container: $CLIENT_CONTAINER"

echo -e "\nChecking files in client container:"
echo "- Root web directory:"
docker exec $CLIENT_CONTAINER ls -la /web

echo -e "\n- Admin directory:"
docker exec $CLIENT_CONTAINER ls -la /web/admin

echo -e "\n- Serve configuration:"
docker exec $CLIENT_CONTAINER cat /web/serve.json || echo "serve.json not found"

echo -e "\nChecking client container logs..."
docker logs $CLIENT_CONTAINER | tail -n 20

echo -e "\nTesting endpoints:"
echo -e "- Main page (/ or /index.html):"
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:8000/

echo -e "- Admin page (/admin):"
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:8000/admin

echo -e "\nDone. Check results above for any issues."
echo "To access the admin page, visit: http://localhost:8000/admin"
echo "To access the main game page, visit: http://localhost:8000/"

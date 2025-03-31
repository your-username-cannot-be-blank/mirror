#!/bin/bash

default_url="https://rr6---.googlevideo.com/videoplayback?expire=..."
read -p "URL (default $default_url): " url
url=${url:-$default_url}

read -p "Type (1 - http/https (default), 2 - --tlsv1.2 --tls-max 1.2, 3 - --tlsv1.3, 4 - --http3): " type
type=${type:-1}

curl_options=""

case "$type" in
  "2")
    curl_options="--tlsv1.2 --tls-max 1.2"
    ;;
  "3")
    curl_options="--tlsv1.3"
    ;;
  "4")
    curl_options="--http3"
    ;;
esac

if [[ "$type" != "1" ]]; then
    if [[ ! $url =~ ^https?:// ]]; then
        url="https://$url"
    elif [[ $url =~ ^http:// ]]; then
        url="${url/http:/https:}"
    fi
fi

echo "URL: $url"
echo "Type: $type"

times=()

for i in {1..30}; do
  output=$(curl -m 1 -s -o /dev/null $curl_options -w "Status: %{response_code}\tScheme: %{scheme}\tProtocol: %{http_version}\tTime: %{time_starttransfer} sec\tRemote_ip: %{remote_ip}\tRemote_port: %{remote_port}\n" \
    -X POST \
    -H "authority: rr6---.googlevideo.com" \
    -H "accept: */*" \
    -H "accept-encoding: gzip, deflate, br, zstd" \
    -H "accept-language: ru" \
    -H "cache-control: no-cache" \
    -H "content-length: 4577" \
    -H "dnt: 1" \
    -H "origin: https://www.youtube.com" \
    -H "pragma: no-cache" \
    -H "priority: u=1, i" \
    -H "referer: https://www.youtube.com/" \
    -H "sec-ch-ua: \"Google Chrome\";v=\"129\", \"Not=A?Brand\";v=\"8\", \"Chromium\";v=\"129\"" \
    -H "sec-ch-ua-arch: \"x86\"" \
    -H "sec-ch-ua-bitness: \"64\"" \
    -H "sec-ch-ua-form-factors: \"Desktop\"" \
    -H "sec-ch-ua-full-version: \"129.0.6668.70\"" \
    -H "sec-ch-ua-full-version-list: \"Google Chrome\";v=\"129.0.6668.70\", \"Not=A?Brand\";v=\"8.0.0.0\", \"Chromium\";v=\"129.0.6668.70\"" \
    -H "sec-ch-ua-mobile: ?0" \
    -H "sec-ch-ua-model: \"\"" \
    -H "sec-ch-ua-platform: \"Windows\"" \
    -H "sec-ch-ua-platform-version: \"10.0.0\"" \
    -H "sec-ch-ua-wow64: ?0" \
    -H "sec-fetch-dest: empty" \
    -H "sec-fetch-mode: cors" \
    -H "sec-fetch-site: cross-site" \
    -H "user-agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/129.0.0.0 Safari/537.36" \
    --data-raw "x" \
    "$url")

  echo "$output"
  time=$(echo "$output" | cut -f 4 | cut -d ' ' -f 2)
  times+=("$time")
done
       
sum=0
for time in "${times[@]}"; do
  sum=$(awk "BEGIN {print $sum + $time}")
done

mean=$(awk "BEGIN {print $sum / ${#times[@]}}")

sum_sq_diff=0
for time in "${times[@]}"; do
  sq_diff=$(awk "BEGIN {print ($time - $mean)^2}")
  sum_sq_diff=$(awk "BEGIN {print $sum_sq_diff + $sq_diff}")
done

variance=$(awk "BEGIN {print $sum_sq_diff / ${#times[@]}}")
std=$(awk "BEGIN {print sqrt($variance)}")

min=${times[0]}
max=${times[0]}

for time in "${times[@]}"; do
  if awk "BEGIN {exit ($time < $min) ? 0 : 1}"; then
    min=$time
  fi
  if awk "BEGIN {exit ($time > $max) ? 0 : 1}"; then
    max=$time
  fi
done

echo -e "Minimum Time:\t\t\t$min sec"
echo -e "Mean Time:\t\t\t$mean sec"
echo -e "Maximum Time:\t\t\t$max sec"
echo -e "Standard Deviation Time:\t$std sec"

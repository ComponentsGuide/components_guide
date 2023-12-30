defmodule ComponentsGuide.Wasm.CloudflareDNS do
  # curl -H "accept: application/dns-json" "https://1.1.1.1/dns-query?name=icing.space&type=TXT"
  # curl -o /dev/null -s -w 'Establish Connection: %{time_connect}s\nTTFB: %{time_starttransfer}s\nTotal: %{time_total}s\n' -H "accept: application/dns-json" "https://1.1.1.1/dns-query?name=icing.space&type=TXT"
end

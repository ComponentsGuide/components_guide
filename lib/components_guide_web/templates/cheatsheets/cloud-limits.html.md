# Cloud Limits

## Storage

<svg viewbox="0 0 270 160" width="540" height="360" class="border border-gray-800 rounded-lg">
  <title>Cloud Storage Limits</title>
  <g fill="#eb4859">
    <circle cx="50" cy="20" r="<%= 10.0 * :math.sqrt(0.065 / :math.pi()) %>" />
    <circle cx="50" cy="42" r="<%= 10.0 * :math.sqrt(0.4 / :math.pi()) %>" />
    <circle cx="50" cy="65" r="<%= 10.0 * :math.sqrt(1.048 / :math.pi()) %>" />
    <circle cx="50" cy="115" r="<%= 10.0 * :math.sqrt(26.12 / :math.pi()) %>" />
  </g>
  <g fill="currentColor" style="font-size: 10px; alignment-baseline: central;">
    <text x="60" y="23">TCP packet: 64KiB</text>
    <text x="63" y="45">DynamoDB attribute: 400KB</text>
    <text x="66" y="68">GCP Datastore entity: 1MiB</text>
    <text x="90" y="118">Cloudflare KV entry: 25MiB</text>
  </g>
</svg>

- TCP packet: 65,535 bytes (64KiB − 1 byte)
- Max size of DynamoDB attribute key & value: 400KB
- Max size of GCP Datastore entity: 1,048,572 bytes (1MiB − 4 bytes)
- Max size of Cloudflare KV entry: 25MiB
- Max size of Gmail attachment: 25MiB
- Max size of S3 Object: 5TB
  - Max size of single PUT: 5GB
  - Multipart upload part size: 5MiB to 5GiB
  - S3 Metadata: 2KB

----

<svg viewbox="0 0 20 10" width="500" height="250">
  <g fill="#d1272e">
    <circle cx="2" cy="4" r="<%= :math.sqrt(0.065 / :math.pi()) %>" />
    <circle cx="4" cy="4" r="<%= :math.sqrt(0.4 / :math.pi()) %>" />
    <circle cx="7" cy="4" r="<%= :math.sqrt(1.048 / :math.pi()) %>" />
    <circle cx="13" cy="4" r="<%= :math.sqrt(26.12 / :math.pi()) %>" />
  </g>
</svg>

# Cloud Limits

## Storage

<svg viewbox="0 0 24 16" width="480" height="360" class="border border-gray-800 rounded-lg">
  <title>Cloud Storage Limits</title>
  <g fill="#eb4859">
    <circle cx="5" cy="2" r="<%= :math.sqrt(0.065 / :math.pi()) %>" />
    <circle cx="5" cy="4.2" r="<%= :math.sqrt(0.4 / :math.pi()) %>" />
    <circle cx="5" cy="6.5" r="<%= :math.sqrt(1.048 / :math.pi()) %>" />
    <circle cx="5" cy="11.5" r="<%= :math.sqrt(26.12 / :math.pi()) %>" />
  </g>
  <g fill="currentColor" style="font-size: 1px; alignment-baseline: central;">
    <text x="6" y="2.3" class="small">TCP packet: 64KiB</text>
    <text x="6.3" y="4.5" class="small">DynamoDB attribute: 400KB</text>
    <text x="6.6" y="6.8" class="small">GCP Datastore entity: ~1MiB</text>
    <text x="9" y="11.8" class="small">Cloudflare KV entry: 25MiB</text>
  </g>
</svg>

- TCP packet: 65,535 bytes (64KiB - 1 byte)
- Max size of DynamoDB attribute key & value: 400KB
- Max size of GCP Datastore entity: 1,048,572 bytes (1MiB - 4 bytes)
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

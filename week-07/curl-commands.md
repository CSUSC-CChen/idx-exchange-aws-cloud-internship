# Week 7 curl Commands

API: `property-api-http`, an HTTP API in us-east-1

Route: `GET /properties/{id}`, which invokes Lambda `get-property`, which reads DynamoDB table `Properties`

## Found listing (200)

```bash
curl https://j7pdoclzuc.execute-api.us-east-1.amazonaws.com/properties/R100234
```

Output:

```json
{"L_SystemPrice": "450000", "L_ListingID": "R100234", "L_Status": "Active", "L_Keyword2": "3", "LM_Int2_3": "1450", "LM_Dec_3": "2", "L_City": "Sacramento"}
```

## Missing listing (404)

```bash
curl -i https://j7pdoclzuc.execute-api.us-east-1.amazonaws.com/properties/R999999
```

Output:

```
HTTP/2 404
date: Sat, 14 Nov 2026 00:43:52 GMT
content-type: application/json
content-length: 22
apigw-requestid: Gzg_cjY6IAMEYag=

{"error": "not found"}
```

## Notes

- The handbook's Lambda returns a 200 with `{}` for a missing listing. I added a 404 response so it matches PropertyLite's EC2 `/properties/<listing_id>` route.
- DynamoDB stores numbers without trailing zeros, so `LM_Dec_3` returns `"2"` here. PropertyLite on EC2 returns `"2.0"` because it reads the CSV as text.
- This API URL stops working after the Week 7 cleanup.

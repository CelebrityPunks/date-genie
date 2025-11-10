#!/bin/bash
curl -X POST http://localhost:3000/api/search \
  -H "Content-Type: application/json" \
  -d '{"city": "San Diego", "radius": 10, "budget": 80, "category": "restaurant"}' | jq


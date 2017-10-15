#!/bin/bash

kubectl proxy &
curl http://localhost:8001/api/v1

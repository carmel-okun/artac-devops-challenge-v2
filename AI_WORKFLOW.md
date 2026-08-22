- Which AI tools you used and for what tasks
- 2-3 specific examples of prompts that worked well
- At least 1 example where AI gave you something wrong or suboptimal, and how you caught it
- Your honest estimate of time saved vs. doing it manually
- Total time spent on the assignment

---------
AI Tools:
---------
- Claude Chat
- 

-------------------------------------
Examples of prompts that worked well:
-------------------------------------
- I have a home assignment for a job, I got a github repo with a python ML prediction API app and some of it's deployment infrastructure files such as Dockerfile, terraform/, .github/workflows/ci.yml, first I tried to build the docker image and run it to test it's endpoints (/predict, /health, /ready) on my windows pc with docker desktop installed, the build and run docker commands finish successfully, now write for me the command to test each endpoint, here is the info of the endpoint given to me:
A FastAPI service that serves a pre-trained scikit-learn sentiment classifier.
Endpoint    Method    Description
/predict    POST    Accepts {"text": "..."}, returns {"sentiment": "positive/negative", "confidence": 0.92}
/health    GET    Liveness probe — returns 200 if the server process is running
/ready    GET    Readiness probe — returns 200 only after the model is loaded and ready to serve

----------------------------------------------------------------------------
Example where AI gave me something wrong or suboptimal, and how I caught it:
----------------------------------------------------------------------------
- Claude's suggestion of the prompt to write the endpoint check for /predict:

PowerShell (using Invoke-RestMethod):
```powershell
Invoke-RestMethod -Uri http://localhost:8080/predict -Method Post -ContentType "application/json" -Body '{"text": "I love this product, it works great!"}'
```

curl.exe:
```
curl.exe -X POST http://localhost:8080/predict -H "Content-Type: application/json" -d "{\"text\": \"I love this product, it works great!\"}"
```

Note the escaped quotes — cmd/PowerShell handle quoting around JSON differently than bash, so this is the safest form. Expect something like:

```json
{"sentiment": "positive", "confidence": 0.92}
```

I got:
```
PS C:\Users\carmel\...\ArtAc\artac-devops-challenge-v2> Invoke-RestMethod -Uri http://localhost:8080/predict -Method Post -ContentType "application/json" -Body '{"text": "I love this product, it works great!"}'
Invoke-RestMethod : Internal Server Error
At line:1 char:1
+ Invoke-RestMethod -Uri http://localhost:8080/predict -Method Post -Co ...
+ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : InvalidOperation: (System.Net.HttpWebRequest:HttpWebRequest) [Invoke-RestMethod], WebException
    + FullyQualifiedErrorId : WebCmdletWebResponseException,Microsoft.PowerShell.Commands.InvokeRestMethodCommand
PS C:\Users\carmel\...\ArtAc\artac-devops-challenge-v2>
```
```
PS C:\Users\carmel\...\ArtAc\artac-devops-challenge-v2> curl.exe -X POST http://localhost:8080/predict -H "Content-Type: application/json" -d "{\"text\": \"I love this product, it works great!\"}"
{"detail":[{"type":"json_invalid","loc":["body",1],"msg":"JSON decode error","input":{},"ctx":{"error":"Expecting property name enclosed in double quotes"}}]}curl: (3) URL rejected: Malformed input to a URL function
curl: (6) Could not resolve host: love
curl: (6) Could not resolve host: this
curl: (6) Could not resolve host: product
curl: (6) Could not resolve host: it
curl: (6) Could not resolve host: works
curl: (3) URL rejected: Bad hostname
PS C:\Users\carmel\...\ArtAc\artac-devops-challenge-v2>
```

issue: Claude gave me a broken curl.exe command since windows cmd / PowerShell escaping syntax doesn't work like in bash


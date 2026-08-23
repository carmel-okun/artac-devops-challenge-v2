- Which AI tools you used and for what tasks
- 2-3 specific examples of prompts that worked well
- At least 1 example where AI gave you something wrong or suboptimal, and how you caught it
- Your honest estimate of time saved vs. doing it manually
- Total time spent on the assignment

---------
AI Tools:
---------
- Claude Chat - I mostly used Claude Chat for some general questions in order to decide which solution is best, for example whether it is best practice to use python venv for the pip install command in the Dockerfile compared to using --target attribute, I also used Claude Chat for writing for me some commands such as the curl.exe/PowerShell command for testing the app's endpoints, and asking for further improvements on the Dockerfile.
- 

-------------------------------------
Examples of prompts that worked well:
-------------------------------------
- I have a home assignment for a job, I got a github repo with a python ML prediction API app and some of it's deployment infrastructure files such as Dockerfile, terraform/, .github/workflows/ci.yml, first I tried to build the docker image and run it to test it's endpoints (/predict, /health, /ready) on my windows pc with docker desktop installed, the build and run docker commands finish successfully, now write for me the command to test each endpoint, here is the info of the endpoints given to me:
```
A FastAPI service that serves a pre-trained scikit-learn sentiment classifier.
Endpoint    Method    Description
/predict    POST    Accepts {"text": "..."}, returns {"sentiment": "positive/negative", "confidence": 0.92}
/health    GET    Liveness probe — returns 200 if the server process is running
/ready    GET    Readiness probe — returns 200 only after the model is loaded and ready to serve
```

- ok so I want to use this Dockerfile:
```
FROM python:3.12-slim AS builder

WORKDIR /app

COPY requirements.txt .

# Install into a venv to isolate the installed deps and copy just this dir into the final stage
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"
RUN pip install --no-cache-dir -r requirements.txt

FROM python:3.12-slim

WORKDIR /app

# Copy the pre-built venv dir
COPY --from=builder /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

COPY . .

RUN useradd --system --no-create-home appuser \
    && chown -R appuser:appuser /app
USER appuser

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8080/health')"

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8080"]
```
do you have any suggestions on how to improve it and make it more production-ready?
can we combine some layers maybe?

- 

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

------------------------------------------------------
My honest estimate of time saved vs. doing it manually
------------------------------------------------------
- Part 1: Get It Running:
I found the related lines in the container logs pointing to scikit-learn pinned version right away, but without checking with AI if that is the true reason and that I should actually pin to the version that the app was built with and that it is in fact version 1.8.0 it would take me a few more minutes up to half an hour finding the answer in google when pasting the error lines.

- Part 2: Assess the Codebase:
I used Claude Chat for suggestions on how to improve the Dockerfile by using multi stage setup, and a slim python image as base image, without AI I would need to search online for a slim python image, check if it misses any deps for our "python ML prediction API app", and I would probably run much more test containers, so maybe a couple of hours more.

----------------------------------
Total time spent on the assignment
----------------------------------
22/8/26
10:40 - 13:00 (Assessing the whole assignment - 2 hours 40 minutes)
13:40 - 18:00 (Solving Part 1 - 4 hours 20 minutes)
total: 7 hours

23/8/26
12:00 - 12:37
13:14 - 14:24
14:44 - 
(optimizing the Dockerfile - 1 hours and 47 minutes)

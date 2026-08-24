1. What you found — describe the issue clearly
2. Classification — is this a Bug, an Intentional Trade-off, or something that Needs Improvement?
3. Contractor's reasoning — does the DECISIONS.md mention it? Do you agree or disagree with their rationale?
4. What you did — did you fix it, keep it, or modify it? Why?

-------------------------
Building the docker image
-------------------------
1. 

----------------------------
Running the docker container
----------------------------
1. 

-----------------------
Testing the 3 endpoints
-----------------------
1. What I found:
/predict endpoint returns "Internal Server Error",
I checked the container's logs and found:
```
/usr/local/lib/python3.12/site-packages/sklearn/base.py:380: InconsistentVersionWarning: Trying to unpickle estimator TfidfTransformer from version 1.8.0 when using version 1.6.1. This might lead to breaking code or invalid results. Use at your own risk. For more info please refer to:
https://scikit-learn.org/stable/model_persistence.html#security-maintainability-limitations
  warnings.warn(
/usr/local/lib/python3.12/site-packages/sklearn/base.py:380: InconsistentVersionWarning: Trying to unpickle estimator TfidfVectorizer from version 1.8.0 when using version 1.6.1. This might lead to breaking code or invalid results. Use at your own risk. For more info please refer to:
https://scikit-learn.org/stable/model_persistence.html#security-maintainability-limitations
  warnings.warn(
/usr/local/lib/python3.12/site-packages/sklearn/base.py:380: InconsistentVersionWarning: Trying to unpickle estimator LogisticRegression from version 1.8.0 when using version 1.6.1. This might lead to breaking code or invalid results. Use at your own risk. For more info please refer to:
https://scikit-learn.org/stable/model_persistence.html#security-maintainability-limitations
  warnings.warn(
/usr/local/lib/python3.12/site-packages/sklearn/base.py:380: InconsistentVersionWarning: Trying to unpickle estimator Pipeline from version 1.8.0 when using version 1.6.1. This might lead to breaking code or invalid results. Use at your own risk. For more info please refer to:
https://scikit-learn.org/stable/model_persistence.html#security-maintainability-limitations
  warnings.warn(
```
```
INFO:     172.17.0.1:34682 - "POST /predict HTTP/1.1" 500 Internal Server Error
ERROR:    Exception in ASGI application
Traceback (most recent call last):
...
AttributeError: 'LogisticRegression' object has no attribute 'multi_class'
```

2. Classification:
This is a BUG

3. Contractor's reasoning:
The DECISIONS.md mentioned the pinned scikit-learn version to 1.6.1 for stability, I disagree with their rationale since it breaks the functionality of /predict endpoint which is the essence of the app

4. What I did, and why?:
Since the bug is in the code side I fixed it by asking Claude if I'm right about the source of the issue being the scikit-learn version in requirements.txt, and how should I remediate it, then I tried to pin the version to 1.8.0 as implied in the WARNs in the container logs, tested it and it works!
Why I did it? because the /predict endpoint doesn't work otherwise

-------------------------
Optimizing the Dockerfile
-------------------------

### Single/multi-stage build & Base image: python:3.12
1. What I found:
The given Dockerfile produces a docker image pretty large (~1.4GB), single staged, contains irelevent files.
2. Classification:
This is something that Needs Improvement.
3. Contractor's reasoning:
The DECISIONS.md mention the single stage and the big python base image, saying they both caused issues with dependencies, I used venv for the multi-stage and it worked and using slim python image didn't lack any deps or caused any errors, so I disagree with their rationale.
4. What I did, and why?:
I modified the Dockerfile to use a builder stage and the final stage, using python venv to run pip install in it and copy it to the final stage, I modified the images for both stages to use python3.12-slim which was enough and added .dockerignore file to exclude irelevent files such as *.md, terraform dir/, tests/ dir.
Why I did it? because the resulting docker image was 70% smaller then the original one.

### Health checks
1. What I found:
The HEALTHCHECK only uses /health endpoint and not using /ready.
2. Classification:
This is an Intentional Trade-off.
3. Contractor's reasoning:
The DECISIONS.md mention the usage of only /health endpoint saying both /health and /ready endpoints return the same 200 so they chose /health since it's the standard name, I agree with their rationale, although they serve different purposes, /ready only returns 200 once the model is loaded, meaning, if /ready passes, the process is definitely alive too.
4. What I did, and why?:
I kept it as is.
Why I did it? because the HEALTHCHECK instruction is only about the process being healthy and not crushing then I would keep it as is unless the team/TL will decide otherwise.

### Pinned digest
1. What I found:
The base image "python3.12-slim" is not pinned to a precise sha256 meaning it will change a bit on every security patch, if I would pin it to a sha256, we would get 100% reproducible builds, to the byte.
2. Classification:
This is something that Needs Improvement.
3. Contractor's reasoning:
The DECISIONS.md didn't mention it.
4. What I did, and why?:
I modified it to a specific patch version tag (python:3.12.14-slim) instead of pinning to a specific sha256.
Why I did it? because it is more precise than "python:3.12-slim" and more clear to the eye than pinnning a long sha256.

------------
Fixing CI/CD
------------
### docker push failed
1. What I found:
In the "Build Image" job in the "Build and push" step, the docker push command failed with:
```
Error: buildx failed with: ERROR: failed to build: failed to solve: failed to push ghcr.io/carmel-okun/artac-devops-challenge-v2:latest: denied: installation not allowed to Create organization package
```
meaning the action was denied since it was missing the write permission for packages.
2. Classification:
This is a Bug.
3. Contractor's reasoning:
The DECISIONS.md didn't mention it.
4. What I did, and why?:
I fixed it by adding the "permissions:" block to the specific required job, that way the docker push command has the necessary permissions to finish the action while this write permission is scoped only to that job instead of editing the global GitHub Actions settings, which is a production best practice.
Why I did it? because without this permission, the docker push command failed, and I scoped it to only this job in order to follow and keep security best practices where open permissions are allowed only to what need it.

### Job dependencies & docker image tag best practice
1. What I found:
The "test", "security-scan" and "deploy" jobs in ci.yml are all needing "build" job, while the best practice is to make "deploy" job wait for the "test" and "security-scan" jobs to finish first.
The docker image built with a tag "latest" which is not production-ready. 
2. Classification:
This is something that Needs Improvement.
3. Contractor's reasoning:
The DECISIONS.md didn't mention it.
4. What I did, and why?:
I modified it by replacing the "needs:" in the "deploy" job from "build" to "test, security-scan".
I modified it by replacing the "tags:" in the "build" job from "...:latest" to "...:${{ github.run_number }}".
Why I did it? because that way, the "deploy" job is waiting until both "test" and "security-scan" jobs finished successfully and only then it runs.
because that way, each run of this workflow indentify separately, that way we can trace back each instance of that workflow.

### Trivy Configuration
1. What I found:
The configuration "ignore-unfixed: true" is suppressing vulnerabilities that are impossible to remediate right now, the findings were in perl-base (3 findings), a package that comes bundled with the "python:3.12-slim" Debian base image, who has no available patchs at the moment.
2. Classification:
This is an Intentional Trade-off.
3. Contractor's reasoning:
The DECISIONS.md mention the use of this configuration and I agree with their rationale because there is currently nothing we could upgrade to that would resolve these vulnerabilities, even if we wanted to.
4. What I did, and why?:
I kept it as is, although if we decide to for example, keep track on those findings, it is possible to remove that configuration and instead use a ".trivyignore" file with a list of CVE IDs (along with a name and a comment/reference) we already encountered and automatically add each new one to the list, this way we keep those findings documented while allowing a clear CI/CD flow.
Why I did it? because there's no reason to block CI on unfixable issues.


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
Since the bug is in the code side I fixed it by asking Claude if I'm right about the source of the issue being the scikit-learn version in requirements.txt, and how should I mitigate it, then I tried to pin the version to 1.8.0 as implied in the WARNs in the container logs, tested it and it works!
why I did it? because the /predict endpoint doesn't work otherwise


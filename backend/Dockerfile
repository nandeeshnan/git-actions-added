# FROM python:3.12
# WORKDIR /backend/app
# COPY app/requirements.txt .
# RUN pip install --no-cache-dir -r requirements.txt
# COPY app/ .
# EXPOSE 8000
# CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]


FROM python:3.12-alpine AS builder
WORKDIR /backend/app
RUN apk add --no-cache gcc musl-dev libffi-dev
COPY app/requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

FROM python:3.12-alpine
WORKDIR /backend/app
COPY --from=builder /install /usr/local
COPY app/ .
EXPOSE 8000
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]

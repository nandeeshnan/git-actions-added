# # -------- STAGE 1: Build --------
#     FROM python:3.9-slim AS builder

#     # Set the working directory inside the container
#     WORKDIR /frontend
    
#     # Copy all static files into the container
#     COPY . /frontend
    
#     # -------- STAGE 2: Production --------
#     FROM nginx:alpine
    
#     # Remove default Nginx static files
#     RUN rm -rf /usr/share/nginx/html/*
    
#     COPY --from=builder /frontend /usr/share/nginx/html
#     EXPOSE 80
    
#     # Start Nginx
#     CMD ["nginx", "-g", "daemon off;"]
FROM nginx:alpine
RUN rm -rf /usr/share/nginx/html/*
COPY . /usr/share/nginx/html/
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]

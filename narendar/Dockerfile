FROM nginx:alpine

# Copy the HTML file to nginx's default html directory
COPY index.html /usr/share/nginx/html/index.html

# Copy the images directory
COPY images/ /usr/share/nginx/html/images/

# Expose port 80
EXPOSE 80

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
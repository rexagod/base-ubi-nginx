# Nginx Base Image

A lightweight NGINX server based on ubi-minimal image.

# About

This container image runs NGINX as a non-root container. 

# Defaults

By default the image runs on http, and expects our files to be in `/var/html/www`

The user can provide their own certificates and nginx config, in order to use https. 
Checkout [this example](https://github.com/rexagod/base-ubi-nginx/blob/364964bf3031d843d337d3052198676bee0764bd/examples/https) as reference.


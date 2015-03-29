_site/:
	jekyll build

clean:
	rm -rf _site
	rm -rf .sass-cache

deploy:
	rsync -avz -e ssh ./_site/ uberspace:./html/	

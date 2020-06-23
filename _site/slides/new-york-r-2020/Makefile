all:new-york-r.html website

new-york-r.html:new-york-r.Rmd my.css
	Rscript -e 'library("rmarkdown"); render("new-york-r.Rmd")'

website:new-york-r.html
	cp new-york-r.html index.html

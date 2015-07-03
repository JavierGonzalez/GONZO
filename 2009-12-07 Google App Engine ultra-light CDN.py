from os import environ
from google.appengine.api import memcache
from google.appengine.ext.webapp.util import webapp, run_wsgi_app
import datetime

class Mirror(webapp.RequestHandler):
   
    def get(self):
	host = environ["SERVER_NAME"]
        url = host + self.request.path
        data = memcache.get(url)
	
	exp_seg = 259200 # 3d
	# if host == "ocio.teoriza.com" or host == "actualidad.teoriza.org": exp_seg = 1800 # 30m
	# print url

        if data == None:
            try:
                if host == "vp.cdn.teoriza.com" or host == "cdn.virtualpol.com": host = "www.virtualpol.com/img"
                elif host == "pc.cdn.teoriza.com": host = "www.perfectcine.com/img"
		else: host = "img-src.teoriza.com"

                from google.appengine.api import urlfetch
		# host.replace(".teoriza.", "-src.teoriza.")
		data = urlfetch.fetch("http://" + host + self.request.path, method = urlfetch.GET, allow_truncated = False, follow_redirects = True, deadline = None)
		exp_time = exp_seg

                datetime_now = datetime.datetime.utcnow()
                data.headers["Last-Modified"] = datetime_now.strftime("%a, %d %b %Y %H:%M:%S GMT")

		import logging
                logging.info("Peticion: " + url)

            except data.status_code != 200 or urlfetch.DownloadError or urlfetch.ResponseTooLargeError:
                import logging
                logging.critical("Timeout: " + url)
                exp_time = 180 # 3m

            memcache.add(url, data, exp_time)

	self.response.headers["Last-Modified"] = data.headers["Last-Modified"]
        expires_date = datetime.datetime.utcnow() + datetime.timedelta(seconds=exp_seg)
        self.response.headers["Expires"] = expires_date.strftime("%a, %d %b %Y %H:%M:%S GMT")

	if data.headers["Content-Type"] == "text/html": self.response.headers["Cache-Control"] = "private, max-age=600"
	else: self.response.headers["Cache-Control"] = "public, max-age=" + str(exp_seg)

        self.response.headers["Content-Type"] = data.headers["Content-Type"]
        self.response.out.write(data.content)

def main():
    run_wsgi_app(webapp.WSGIApplication([(".*", Mirror)], debug=True))

if __name__ == "__main__":
  main()
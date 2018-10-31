FROM plone:5.1.4

COPY site.cfg /plone/instance/
RUN gosu plone buildout -c site.cfg

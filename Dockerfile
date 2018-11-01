FROM plone:5.1.4

COPY src/ /plone/instance/src/
COPY site.cfg /plone/instance/
RUN chown -R plone . \
 && gosu plone buildout -c site.cfg

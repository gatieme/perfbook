SHELL = /bin/bash

LATEXSOURCES = \
	perfbook.tex \
	legal.tex \
	glossary.tex \
	qqz.sty origpub.sty \
	noindentafter.sty \
	pfbook.cls \
	ushyphex.tex pfhyphex.tex \
	*/*.tex \
	*/*/*.tex

LST_SOURCES := $(wildcard CodeSamples/formal/promela/*.lst) \
	$(wildcard appendix/styleguide/*.c)

LATEXGENERATED = autodate.tex qqz.tex contrib.tex origpub.tex

ABBREVTARGETS := tcb 1c hb msns mss mstx msr msn msnt 1csf qq 1cqq nq 1cnq

PDFTARGETS := perfbook.pdf $(foreach v,$(ABBREVTARGETS),perfbook-$(v).pdf)

EPSSOURCES_FROM_TEX := \
	SMPdesign/DiningPhilosopher5.eps \
	SMPdesign/DiningPhilosopher5TB.eps \
	SMPdesign/DiningPhilosopher4part-b.eps \
	SMPdesign/DiningPhilosopher5PEM.eps

DOTSOURCES := $(wildcard */*.dot)

EPSSOURCES_FROM_DOT := $(DOTSOURCES:%.dot=%.eps)

FIGSOURCES := $(wildcard */*.fig) $(wildcard */*/*.fig)

EPSSOURCES_FROM_FIG := $(FIGSOURCES:%.fig=%.eps)

SVGSOURCES := $(wildcard */*.svg)
FAKE_EPS_FROM_SVG := $(SVGSOURCES:%.svg=%.eps)
PDFTARGETS_OF_SVG := $(SVGSOURCES:%.svg=%.pdf)

OBSOLETE_FILES = extraction $(FAKE_EPS_FROM_SVG) CodeSamples/snippets.mk

EPSSOURCES_DUP := \
	$(wildcard */*.eps) \
	$(wildcard */*/*.eps) \
	$(EPSSOURCES_FROM_TEX) \
	$(EPSSOURCES_FROM_DOT) \
	$(EPSSOURCES_FROM_FIG)

EPSSOURCES := $(sort $(filter-out $(OBSOLETE_FILES),$(EPSSOURCES_DUP)))

PDFTARGETS_OF_EPS := $(EPSSOURCES:%.eps=%.pdf)

EPSORIGIN := $(filter-out $(EPSSOURCES_FROM_TEX) $(EPSSOURCES_FROM_DOT) $(EPSSOURCES_FROM_FIG),$(EPSSOURCES))

PDFTARGETS_OF_EPSORIG := $(EPSORIGIN:%.eps=%.pdf)

PDFTARGETS_OF_EPSOTHER := $(filter-out $(PDFTARGETS_OF_EPSORIG),$(PDFTARGETS_OF_EPS))

BIBSOURCES := bib/*.bib alphapf.bst

# required commands
DOT := $(shell which dot 2>/dev/null)
FIG2EPS := $(shell which fig2eps 2>/dev/null)
A2PING := $(shell which a2ping 2>/dev/null)
INKSCAPE := $(shell which inkscape 2>/dev/null)
ifdef INKSCAPE
  INKSCAPE_ONE := $(shell inkscape --version | grep -c "Inkscape 1")
endif
LATEXPAND := $(shell which latexpand 2>/dev/null)
QPDF := $(shell which qpdf 2>/dev/null)

# required fonts
STEELFONT := $(shell fc-list | grep -c -i steel)
URWPS := $(shell fc-list | grep "Nimbus Mono PS" | wc -l)

# required font packages
FONTPACKAGES := $(shell kpsewhich newtxtext.sty nimbusmono.sty newtxtt.sty newtxsf.sty inconsolata.sty couriers.sty mdsymbol.sty)
NEWTXTEXT := $(findstring newtxtext,$(FONTPACKAGES))
NIMBUSMONO := $(findstring nimbusmono,$(FONTPACKAGES))
NEWTXTT := $(findstring newtxtt,$(FONTPACKAGES))
COURIERS := $(findstring couriers,$(FONTPACKAGES))
NEWTXSF := $(findstring newtxsf,$(FONTPACKAGES))
INCONSOLATA := $(findstring inconsolata,$(FONTPACKAGES))
MDSYMBOL := $(findstring mdsymbol,$(FONTPACKAGES))

# for line break in error text
define n


endef

ifeq ($(URWPS),0)
FIXSVGFONTS   = utilities/fixsvgfonts.sh
FIXANEPSFONTS = utilities/fixanepsfonts.sh
else
FIXSVGFONTS   = utilities/fixsvgfonts-urwps.sh
FIXANEPSFONTS = utilities/fixanepsfonts-urwps.sh
  ifeq ($(MDSYMBOL),)
    NEEDMDSYMBOL := 1
  else
    NEEDMDSYMBOL := 0
  endif
endif

STEELFONTID := $(shell fc-list | grep -i steel | grep -c Steel)

ifdef A2PING
  GS_950_OR_LATER := $(shell gs --version | grep -c -E "9\.[5-9].?")
  A2PING_277P := $(shell a2ping --help 2>&1 | grep -c "2.77p,")
  A2PING_283P := $(shell a2ping --help 2>&1 | grep -c "2.83p,")
  ifeq ($(A2PING_277P),1)
    A2PING_GSCNFL := 1
  else
    ifeq ($(A2PING_283P),1)
      ifeq ($(GS_950_OR_LATER),1)
        A2PING_GSCNFL := 1
      else
        A2PING_GSCNFL := 0
      endif
    else
      A2PING_GSCNFL := 0
    endif
  endif
endif

LINELABEL_ENV_BEGIN := $(shell grep -l -F '\begin{linelabel}' $(LATEXSOURCES))
LINELABEL_ENV_END   := $(shell grep -l -F '\end{linelabel}'   $(LATEXSOURCES))
LINEREF_ENV_BEGIN   := $(shell grep -l -F '\begin{lineref}'   $(LATEXSOURCES))
LINEREF_ENV_END     := $(shell grep -l -F '\end{lineref}'     $(LATEXSOURCES))
LINELABEL_ENV := $(sort $(LINELABEL_ENV_BEGIN) $(LINELABEL_ENV_END))
LINEREF_ENV   := $(sort $(LINEREF_ENV_BEGIN) $(LINEREF_ENV_END))

CREFPTN    := '\\[Cc](ln)?ref{[^{]+}\s*{[^}]+}'
CREFPAIR   := $(shell grep -l -zo -E $(CREFPTN)   $(LATEXSOURCES))

SOURCES_OF_SNIPPET_ALL := $(shell grep -r -l -F '\begin{snippet}' CodeSamples)
SOURCES_OF_LITMUS      := $(shell grep -r -l -F '\begin[snippet]' CodeSamples)
SOURCES_OF_LTMS        := $(patsubst %.litmus,%.ltms,$(SOURCES_OF_LITMUS))
SOURCES_OF_SNIPPET     := $(filter-out $(SOURCES_OF_LTMS),$(SOURCES_OF_SNIPPET_ALL)) $(SOURCES_OF_LITMUS)
GEN_SNIPPET_D  = utilities/gen_snippet_d.pl utilities/gen_snippet_d.sh

default = $(PERFBOOK_DEFAULT)

ifeq ($(default),)
	targ = perfbook.pdf
else
	targ = $(default)
endif

chkpagegroup = $(PERFBOOK_CHKPAGEGROUP)

.PHONY: all touchsvg clean distclean neatfreak 2c ls-unused $(ABBREVTARGETS) mslm perfbook-mslm.pdf mslmmsg help help-official help-full
all: $(targ)

ifeq ($(MAKECMDGOALS),clean)
else ifeq ($(MAKECMDGOALS),distclean)
else ifeq ($(MAKECMDGOALS),neatfreak)
else
-include CodeSamples/snippets.d
endif

2c: perfbook.pdf

mslm: perfbook-mslm.pdf

perfbook-mslm.pdf: perfbook.pdf mslmmsg

mslmmsg:
	@echo "perfbook-mslm.pdf is promoted to default target,"
	@echo "built as perfbook.pdf."

$(PDFTARGETS): %.pdf: %.tex %.bbl
	sh utilities/runlatex.sh $(basename $@)

$(PDFTARGETS:.pdf=.bbl): %.bbl: %.aux $(BIBSOURCES)
	bibtex $(basename $@)

$(PDFTARGETS:.pdf=.aux): $(LATEXGENERATED) $(LATEXSOURCES) $(LST_SOURCES)
ifeq ($(NEWTXTEXT),)
	$(error Font package 'newtx' not found. See #9 in FAQ-BUILD.txt)
endif
	sh utilities/runfirstlatex.sh $(basename $@)

autodate.tex: perfbook.tex $(LATEXSOURCES) $(BIBSOURCES) $(SVGSOURCES) $(FIGSOURCES) $(DOTSOURCES) $(EPSORIGIN) $(SOURCES_OF_SNIPPET) utilities/fcvextract.pl
	sh utilities/autodate.sh >autodate.tex

perfbook_flat.tex: autodate.tex $(PDFTARGETS_OF_EPS) $(PDFTARGETS_OF_SVG) $(FCVSNIPPETS) $(FCVSNIPPETS_VIA_LTMS)
ifndef LATEXPAND
	$(error --> $@: latexpand not found. Please install it)
endif
	@if [ ! -z "$(LINELABEL_ENV)" -a "$(LINELABEL_ENV)" != " " ]; then \
		echo "'linelabel' used as environment in $(LINELABEL_ENV)." ; \
		echo "------" ; \
		grep -n -B 2 -A 2 -F 'linelabel' $(LINELABEL_ENV) ; \
		echo "------" ; \
		echo "Substitute 'fcvlabel' for 'linelabel' in $(LINELABEL_ENV)." ; \
		exit 1 ; \
	fi
	@if [ ! -z "$(LINEREF_ENV)" -a "$(LINEREF_ENV)" != " " ]; then \
		echo "'lineref' used as environment in $(LINEREF_ENV)." ; \
		echo "------" ; \
		grep -n -B 2 -A 2 -F 'lineref' $(LINEREF_ENV) ; \
		echo "------" ; \
		echo "Substitute 'fcvref' for 'lineref' in $(LINEREF_ENV)." ; \
		exit 1 ; \
	fi
	@if [ ! -z "$(CREFPAIR)" -a "$(CREFPAIR)" != " " ]; then \
		echo "------" ; \
		if grep -q -E $(CREFPTN) $(CREFPAIR) ; then \
			grep -n -B 2 -A 2 -E $(CREFPTN) $(CREFPAIR) ; \
		else \
			grep -zo -B 2 -A 2 -E $(CREFPTN) $(CREFPAIR) ; \
			echo ; \
		fi ; \
		echo "------" ; \
		echo "Need to use \[Cc]refrange or \[Cc]lnrefrangein $(CREFPAIR)." ; \
		exit 1 ; \
	fi
	echo > qqz.tex
	echo > contrib.tex
	echo > origpub.tex
	latexpand --empty-comments perfbook.tex 1> $@ 2> /dev/null

qqz.tex: perfbook_flat.tex
	sh utilities/extractqqz.sh < $< | perl utilities/qqzreorder.pl > $@

contrib.tex: perfbook_flat.tex qqz.tex
	cat $^ | sh utilities/extractcontrib.sh > $@

origpub.tex: perfbook_flat.tex
	sh utilities/extractorigpub.sh < $< > $@

perfbook-tcb.tex: perfbook.tex
	sed -e 's/{tblcptop}{true}/{tblcptop}{false}/' < $< > $@

perfbook-1c.tex: perfbook.tex
	sed -e 's/,twocolumn//' -e 's/setboolean{twocolumn}{true}/setboolean{twocolumn}{false}/' < $< > $@

perfbook-hb.tex: perfbook.tex
	sed -e 's/setboolean{hardcover}{false}/setboolean{hardcover}{true}/' < $< > $@

perfbook-msns.tex: perfbook.tex
	sed -e 's/%msfontstub/\\usepackage{courier}/' < $< > $@

perfbook-mss.tex: perfbook.tex
ifeq ($(COURIERS),)
	$(error Font package 'courier-scaled' not found. See #9 in FAQ-BUILD.txt)
endif
	sed -e 's/%msfontstub/\\usepackage[scaled=.94]{couriers}/' < $< > $@

perfbook-mstx.tex: perfbook.tex
	sed -e 's/%msfontstub/\\renewcommand*\\ttdefault{txtt}/' < $< > $@

perfbook-msr.tex: perfbook.tex
ifeq ($(NIMBUSMONO),)
	$(error Font package 'nimbus15' not found. See #9 in FAQ-BUILD.txt)
endif
	sed -e 's/%msfontstub/\\usepackage[scaled=.94]{nimbusmono}/' \
	    -e 's/{nimbusavail}{false}/{nimbusavail}{true}/' < $< > $@

perfbook-msn.tex: perfbook.tex
ifeq ($(NIMBUSMONO),)
	$(error Font package 'nimbus15' not found. See #9 in FAQ-BUILD.txt)
endif
	sed -e 's/\\renewcommand\*\\ttdefault{lmtt}//' \
	    -e 's/{lmttforcode}{true}/{lmttforcode}{false}/' \
	    -e 's/{nimbusavail}{false}/{nimbusavail}{true}/' < $< > $@

perfbook-msnt.tex: perfbook.tex
ifeq ($(NEWTXTT),)
	$(error Font package 'newtxtt' not found.$nInstall it or try 'make mstx' instead. See #9 in FAQ-BUILD.txt)
endif
ifeq ($(NIMBUSMONO),)
	$(error Font package 'nimbus15' not found. See #9 in FAQ-BUILD.txt)
endif
	sed -e 's/%msfontstub/\\usepackage[zerostyle=a]{newtxtt}/' \
	    -e 's/{qqzgb}{false}/{qqzbg}{true}/' \
	    -e 's/{nimbusavail}{false}/{nimbusavail}{true}/' < $< > $@

perfbook-1csf.tex: perfbook-1c.tex
ifeq ($(NEWTXSF),)
	$(error Font package 'newtxsf' not found. See #9 in FAQ-BUILD.txt)
endif
ifeq ($(INCONSOLATA),)
	$(error Font package 'inconsolata' not found. See #9 in FAQ-BUILD.txt)
endif
ifeq ($(NIMBUSMONO),)
	$(error Font package 'nimbus15' not found. See #9 in FAQ-BUILD.txt)
endif
	sed -e 's/setboolean{sansserif}{false}/setboolean{sansserif}{true}/' \
	    -e 's/{qqzbg}{false}/{qqzbg}{true}/' \
	    -e 's/{nimbusavail}{false}/{nimbusavail}{true}/' \
	    -e 's/%msfontstub/\\usepackage[var0]{inconsolata}[2013\/07\/17]/' < $< > $@

perfbook-qq.tex: perfbook.tex
	sed -e 's/{qqzbg}{false}/{qqzbg}{true}/' < $< > $@

perfbook-1cqq.tex: perfbook-1c.tex
	sed -e 's/{qqzbg}{false}/{qqzbg}{true}/' < $< > $@

perfbook-nq.tex: perfbook.tex
	sed -e 's/setboolean{noqqz}{false}/setboolean{noqqz}{true}/' < $< > $@

perfbook-1cnq.tex: perfbook-1c.tex
	sed -e 's/setboolean{noqqz}{false}/setboolean{noqqz}{true}/' < $< > $@

# Rules related to perfbook_html are removed as of May, 2016

$(EPSSOURCES_FROM_TEX): %.eps: %.tex
	@echo "$< --> $@"
	sh utilities/mpostcheck.sh
	@latex -output-directory=$(shell dirname $<) $< > /dev/null 2>&1
	@dvips -Pdownload35 -E $(patsubst %.tex,%.dvi,$<) -o $@ > /dev/null 2>&1
	@sh $(FIXANEPSFONTS) $@

$(EPSSOURCES_FROM_DOT): %.eps: %.dot
	@echo "$< --> $@"
ifndef DOT
	$(error $< --> $@: dot not found. Please install graphviz)
endif
	@dot -Tps -o $@ $<
	@sh $(FIXANEPSFONTS) $@

$(EPSSOURCES_FROM_FIG): %.eps: %.fig
	@echo "$< --> $@"
ifndef FIG2EPS
	$(error $< --> $@: fig2eps not found. Please install fig2ps)
endif
	@fig2eps --nogv $< > /dev/null 2>&1
	@sh $(FIXANEPSFONTS) $@

$(PDFTARGETS_OF_EPSORIG): %.pdf: %.eps
	@echo "$< --> $@"
ifndef A2PING
	$(error $< --> $@: a2ping not found. Please install it)
endif
ifeq ($(A2PING_GSCNFL),1)
	$(error You need to update a2ping. See #7 in FAQ-BUILD.txt)
endif
	@cp $< $<i
	@sh $(FIXANEPSFONTS) $<i
	@a2ping --below --hires --bboxfrom=compute-gs $<i $@ > /dev/null 2>&1
	@rm -f $<i

$(PDFTARGETS_OF_EPSOTHER): %.pdf: %.eps
	@echo "$< --> $@"
ifndef A2PING
	$(error $< --> $@: a2ping not found. Please install it)
endif
ifeq ($(A2PING_GSCNFL),1)
	$(error a2ping version conflict. See #7 in FAQ-BUILD.txt)
endif
	@a2ping --below --hires --bboxfrom=compute-gs $< $@ > /dev/null 2>&1

$(PDFTARGETS_OF_SVG): %.pdf: %.svg
	@echo "$< --> $@"
ifeq ($(STEELFONT),0)
	$(error "Steel City Comic" font not found. See #1 in FAQ.txt)
endif
ifndef INKSCAPE
	$(error $< --> $@ inkscape not found. Please install it)
endif
ifeq ($(STEELFONTID),0)
	@sh $(FIXSVGFONTS) < $< | sed -e 's/Steel City Comic/Test/g' > $<i
else
	@sh $(FIXSVGFONTS) < $< > $<i
endif
ifeq ($(NEEDMDSYMBOL),1)
	$(error Font package 'mdsymbol' not found. See #9 in FAQ-BUILD.txt)
endif
ifeq ($(INKSCAPE_ONE),0)
	@inkscape --export-pdf=$@ $<i > /dev/null 2>&1
else
	@inkscape --export-file=$@ $<i > /dev/null 2>&1
endif
	@rm -f $<i
ifeq ($(chkpagegroup),on)
ifndef QPDF
	$(error qpdf not found. Please install it)
endif
	@echo "checking page group in $@"
	@qpdf --qdf $@ $@q
	@./utilities/extpagegroup.pl < $@q > $@p
	@diff -q -w $@p pagegroup
	@rm -f $@q $@p
endif

CodeSamples/snippets.d: $(SOURCES_OF_SNIPPET) $(GEN_SNIPPET_D)
	sh ./utilities/gen_snippet_d.sh

$(FCVSNIPPETS):
	@echo "$< --> $@"
	@utilities/fcvextract.pl $< $(subst +,\\+,$(subst @,:,$(basename $(notdir $@)))) > $@
	@utilities/checkfcv.pl $@

$(FCVSNIPPETS_VIA_LTMS):
	@echo "$< --> $@"
	@utilities/fcvextract.pl $< $(subst +,\\+,$(subst @,:,$(basename $(notdir $@)))) > $@
	@utilities/checkfcv.pl $@

$(FCVSNIPPETS_LTMS):
	@echo "$< --> $@"
	@utilities/reorder_ltms.pl $< > $@

help-official:
	@echo "Official targets (Latin Modern Typewriter for monospace font):"
	@echo "  Full,              Abbr."
	@echo "  perfbook.pdf,      2c:   (default) 2-column layout"
	@echo "  perfbook-1c.pdf,   1c:   1-column layout"
	@echo "  perfbook-hb.pdf,   hb:   For hardcover books (2-column)"

help: help-official
	@echo
	@echo "\"make help-full\" will show the list of available targets."

help-full: help-official
	@echo
	@echo "Experimental targets:"
	@echo "  Full,              Abbr."
	@echo "  perfbook-qq.pdf,   qq:   2c with framed Quick Quizzez (1cqq for 1c)"
	@echo "  perfbook-nq.pdf,   nq:   2c without inline Quick Quizzes (1cnq for 1c)"
	@echo "  perfbook-msnt.pdf, msnt: 2c with newtxtt as monospace (non-slashed 0)"
	@echo "  perfbook-mstx.pdf, mstx: 2c with txtt as monospace"
	@echo "  perfbook-msr.pdf,  msr:  2c with regular thickness courier clone"
	@echo "  perfbook-msn.pdf,  msn:  2c with narrow courier clone"

	@echo "  perfbook-1csf.pdf, 1csf: 1c with sans serif font"
	@echo
	@echo "Historical targets:"
	@echo "  perfbook-tcb.pdf,  tcb:  2c with table caption at bottom (prev default)"
	@echo "  perfbook-msns.pdf, msns: 2c with non-scaled courier (orig default)"
	@echo "  perfbook-mss.pdf,  mss:  2c with scaled courier (prev default)"
	@echo
	@echo "Notes:"
	@echo "  - \"msnt\" requires \"newtxtt\". \"mstx\" is a fallback target for older TeX env."
	@echo "  - \"msr\" and \"msn\" require \"nimbus15\"."
	@echo "  - \"msn\" doesn't cover bold face for monospace."
	@echo "  - \"1csf\" requires \"newtxsf\"."
	@echo "  - \"msnt\" and \"1csf\" have framed Quick Quizzes."
	@echo "  - All the targets except for \"msn\" use \"Latin Modern Typewriter\" font"
	@echo "    for code snippets."

clean:
	find . -name '*.aux' -o -name '*.blg' \
		-o -name '*.dvi' -o -name '*.log' \
		-o -name '*.qqz' -o -name '*.toc' -o -name '*.bbl' \
		-o -name '*.pdfp' -o -name '*.pdfq' | xargs rm -f
	rm -f perfbook_flat.tex perfbook*.out perfbook-*.tex
	rm -f $(LATEXGENERATED)
	rm -f CodeSamples/snippets.d
	rm -f *.synctex*
	@rm -f $(OBSOLETE_FILES)

distclean: clean
	sh utilities/cleanpdf.sh
	rm -f $(EPSSOURCES_FROM_DOT) $(EPSSOURCES_FROM_TEX) $(EPSSOURCES_FROM_FIG)
	find . -name '*.fcv' -o -name '*.ltms' | xargs rm -f

touchsvg:
	find . -name '*.svg' | xargs touch

ls-unused:
	find . -name .unused | xargs ls

neatfreak: distclean
	find . -name '*.pdf' | xargs rm -f

.SECONDEXPANSION:
$(ABBREVTARGETS): %: perfbook-$$@.pdf

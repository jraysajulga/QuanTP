--- /Users/jraysajulga/Galaxy/omicron-main_17.05/tools/quanTP/quantp-orig.r	Fri Sep 14 11:22:31 2018
+++ /Users/jraysajulga/Galaxy/omicron-main_17.05/tools/quanTP/quantp-new.r	Mon Nov  5 16:40:43 2018
@@ -418,6 +418,7 @@
 multisample_boxplot = function(df, sampleinfo_df, outfile, fill_leg, user_xlab, user_ylab)
 {
   tempdf = df[,-1, drop=FALSE];
+  rownames(tempdf) = df$Gene;
   tempdf = t(tempdf) %>% as.data.frame();
   tempdf[is.na(tempdf)] = 0;
   tempdf$Sample = rownames(tempdf);
@@ -425,16 +426,21 @@
   tempdf1$Group = sampleinfo_df[tempdf1$Sample,2];
   png(outplot, width = 6, height = 6, units = 'in', res=300);
   # bitmap(outplot, "png16m");
-  if(fill_leg=="Yes")
-  {
-    g = ggplot(tempdf1, aes(x=Sample, y=value, fill=Group)) + geom_boxplot() + labs(x=user_xlab) + labs(y=user_ylab)
-  }else{
-    if(fill_leg=="No")
-    {
-      tempdf1$Group = c("case", "control")
-      g = ggplot(tempdf1, aes(x=Sample, y=value, fill=Group)) + geom_boxplot() + labs(x=user_xlab) + labs(y=user_ylab)
-    }
+  if(fill_leg=="No"){
+    tempdf1$Group = c("case", "control")
   }
+  
+  g = ggplot(tempdf1, aes(x=Sample, y=value, fill=Group)) + geom_boxplot() + labs(x=user_xlab) + labs(y=user_ylab)
+  p <- plot_ly(y = tempdf1$value, x = tempdf1$Sample,
+               color = tempdf1$Group,
+               colors = c("#F35E5A","#18B3B7"),
+               type ="box",
+               hoverinfo = 'text',
+               text = ~paste('Gene: ', tempdf1$variable,
+                             '<br />Value: ', tempdf1$value)) %>%
+    layout(xaxis = list(title = user_xlab), yaxis = list(title = user_ylab))
+  
+  saveWidgetFix(p, file.path(gsub("\\.png", "\\.html", outfile)))
   plot(g);
   dev.off();
 }
@@ -661,6 +667,7 @@
 suppressPackageStartupMessages(library(gplots));
 suppressPackageStartupMessages(library(ggplot2));
 suppressPackageStartupMessages(library(ggfortify));
+suppressPackageStartupMessages(library(plotly));
 
 #===============================================================================
 # Select mode and parse experiment design file
@@ -793,6 +800,39 @@
 TE_df[is.na(TE_df)] = 0;
 PE_df[is.na(PE_df)] = 0;
 
+#===============================================================================
+# Obtain JS/HTML lines for interactive visualization through Plot.ly
+#===============================================================================
+getPlotlyLines = function(name){
+  lines <- readLines(paste(outdir,'/',name,'.html', sep=""))
+  return(list(
+    'prescripts'  = c('',
+                      gsub('script', 'script',
+                           lines[grep('<head>',lines) + 3
+                                 :grep('</head>' ,lines) - 5]),
+                      ''),
+    #'prescripts'  = c('<!--',
+    #                      rev(stringi::stri_reverse(gsub('script', 'script',
+    #                                                     lines[grep('<meta>',lines)[1] + 1
+    #                                                           :grep('</head>' ,lines)[1] - 1]))),
+    #                      '-->'),
+    #'prescripts' = paste('',
+    #                      gsub('script', 'script',
+    #                           lines[grep(lines, pattern='<script src')]),
+    #                      '', sep=''),
+    'plotly_div'  = paste('<!--',
+                          gsub('width:100%;height:400px',
+                               'width:500px;height:500px',
+                               lines[grep(lines, pattern='plotly html-widget')]),
+                          '-->', sep=''),
+    'postscripts' = paste('',
+                          gsub('script', 'script',
+                               lines[grep(lines, pattern='<script type')]),
+                          '', sep='')));
+}
+prescripts <- list()
+postscripts <- list()
+
 
 #===============================================================================
 # Decide based on analysis mode
@@ -857,19 +897,29 @@
     
     # TE Boxplot
     outplot = paste(outdir,"/Box_TE_all_rep.png",sep="",collape="");
-    cat('<table  border=1 cellspacing=0 cellpadding=5 style="table-layout:auto; ">\n',
-    '<tr bgcolor="#7a0019"><th><font color=#ffcc33>Boxplot: Transcriptome data</font></th><th><font color=#ffcc33>Boxplot: Proteome data</font></th></tr>\n',
-    "<tr><td align=center>", '<img src="Box_TE_all_rep.png" width=500 height=500></td>\n', file = htmloutfile, append = TRUE);
     temp_df_te_data = data.frame(TE_df[,1], log(TE_df[,2:length(TE_df)]));
     colnames(temp_df_te_data) = colnames(TE_df);
     multisample_boxplot(temp_df_te_data, sampleinfo_df, outplot, "Yes", "Samples", "Transcript Abundance (log)");
-    
+    lines <- getPlotlyLines('Box_TE_all_rep')
+    prescripts <- c(prescripts, lines$prescripts)
+    postscripts <- c(postscripts, lines$postscripts)
+    cat('<table  border=1 cellspacing=0 cellpadding=5 style="table-layout:auto; ">\n',
+        '<tr bgcolor="#7a0019"><th><font color=#ffcc33>Boxplot: Transcriptome data</font></th><th><font color=#ffcc33>Boxplot: Proteome data</font></th></tr>\n',
+        "<tr><td align=center>", 
+        '<img src="Box_TE_all_rep.png" width=500 height=500>\n',
+        lines$plotly_div,'</td>',
+        file = htmloutfile, append = TRUE);
+
     # PE Boxplot
     outplot = paste(outdir,"/Box_PE_all_rep.png",sep="",collape="");
-    cat("<td align=center>", '<img src="Box_PE_all_rep.png" width=500 height=500></td></tr></table>\n', file = htmloutfile, append = TRUE);
     temp_df_pe_data = data.frame(PE_df[,1], log(PE_df[,2:length(PE_df)]));
     colnames(temp_df_pe_data) = colnames(PE_df);
     multisample_boxplot(temp_df_pe_data, sampleinfo_df, outplot, "Yes", "Samples", "Protein Abundance (log)");
+    lines <- getPlotlyLines('Box_PE_all_rep')
+    #prescripts <- c(prescripts, lines$prescripts)
+    postscripts <- c(postscripts, lines$postscripts)
+    cat("<td align=center>", '<img src="Box_PE_all_rep.png" width=500 height=500>',
+          lines$plotly_div, '</td></tr></table>\n', file = htmloutfile, append = TRUE);
     
     # Calc TE PCA
     outplot = paste(outdir,"/PCA_TE_all_rep.png",sep="",collape="");
@@ -889,19 +939,25 @@
     
     # TE Boxplot
     outplot = paste(outdir,"/Box_TE_rep.png",sep="",collape="");
-    cat('<br><font color="#ff0000"><h3>Sample wise distribution (Box plot) after using ',method,' on replicates </h3></font><table border=1 cellspacing=0 cellpadding=5 style="table-layout:auto; "> <tr bgcolor="#7a0019"><th><font color=#ffcc33>Boxplot: Transcriptome data</font></th><th><font color=#ffcc33>Boxplot: Proteome data</font></th></tr>\n',
-    "<tr><td align=center>", '<img src="Box_TE_rep.png" width=500 height=500></td>\n', file = htmloutfile, append = TRUE);
     temp_df_te_data = data.frame(TE_df[,1], log(TE_df[,2:length(TE_df)]));
     colnames(temp_df_te_data) = colnames(TE_df);
     multisample_boxplot(temp_df_te_data, sampleinfo_df, outplot, "No", "Sample Groups", "Mean Transcript Abundance (log)");
-
+    lines <- getPlotlyLines('Box_TE_rep')
+    #prescripts <- c(prescripts, lines$prescripts)
+    postscripts <- c(postscripts, lines$postscripts)
+    cat('<br><font color="#ff0000"><h3>Sample wise distribution (Box plot) after using ',method,' on replicates </h3></font><table border=1 cellspacing=0 cellpadding=5 style="table-layout:auto; "> <tr bgcolor="#7a0019"><th><font color=#ffcc33>Boxplot: Transcriptome data</font></th><th><font color=#ffcc33>Boxplot: Proteome data</font></th></tr>\n',
+        "<tr><td align=center>", '<img src="Box_TE_rep.png" width=500 height=500>', lines$plotly_div, '</td>\n', file = htmloutfile, append = TRUE);
+    
     # PE Boxplot
     outplot = paste(outdir,"/Box_PE_rep.png",sep="",collape="");
-    cat("<td align=center>", '<img src="Box_PE_rep.png" width=500 height=500></td></tr></table>\n', file = htmloutfile, append = TRUE);
     temp_df_pe_data = data.frame(PE_df[,1], log(PE_df[,2:length(PE_df)]));
     colnames(temp_df_pe_data) = colnames(PE_df);
     multisample_boxplot(temp_df_pe_data, sampleinfo_df, outplot, "No", "Sample Groups", "Mean Protein Abundance (log)");
-
+    lines <- getPlotlyLines('Box_PE_rep')
+    #prescripts <- c(prescripts, lines$prescripts)
+    postscripts <- c(postscripts, lines$postscripts)
+    cat("<td align=center>", '<img src="Box_PE_rep.png" width=500 height=500>', lines$plotly_div, '</td></tr></table>\n', file = htmloutfile, append = TRUE);
+    
     #===============================================================================
     # Calculating log fold change and running the "single" code part 
     #===============================================================================
@@ -931,15 +987,21 @@
   
     # TE Boxplot
     outplot = paste(outdir,"/Box_TE.png",sep="",collape="");
+    multisample_boxplot(TE_df, sampleinfo_df, outplot, "Yes", "Sample (log2(case/control))", "Transcript Abundance fold-change (log2)");
+    lines <- getPlotlyLines('Box_TE')
+    #prescripts <- c(prescripts, lines$prescripts)
+    postscripts <- c(postscripts, lines$postscripts)
     cat('<br><font color="#ff0000"><h3>Distribution (Box plot) of log fold change </h3></font>', file = htmloutfile, append = TRUE);
     cat('<table border=1 cellspacing=0 cellpadding=5 style="table-layout:auto; "> <tr bgcolor="#7a0019"><th><font color=#ffcc33>Boxplot: Transcriptome data</font></th><th><font color=#ffcc33>Boxplot: Proteome data</font></th></tr>\n',
-    "<tr><td align=center>", '<img src="Box_TE.png" width=500 height=500></td>\n', file = htmloutfile, append = TRUE);
-    multisample_boxplot(TE_df, sampleinfo_df, outplot, "Yes", "Sample (log2(case/control))", "Transcript Abundance fold-change (log2)");
+        "<tr><td align=center>", '<img src="Box_TE.png" width=500 height=500>', lines$plotly_div, '</td>\n', file = htmloutfile, append = TRUE);
     
     # PE Boxplot
     outplot = paste(outdir,"/Box_PE.png",sep="",collape="");
-    cat("<td align=center>", '<img src="Box_PE.png" width=500 height=500></td></tr></table>\n', file = htmloutfile, append = TRUE);
     multisample_boxplot(PE_df, sampleinfo_df, outplot, "Yes", "Sample (log2(case/control))", "Protein Abundance fold-change(log2)");
+    lines <- getPlotlyLines('Box_PE')
+    #prescripts <- c(prescripts, lines$prescripts)
+    postscripts <- c(postscripts, lines$postscripts)
+    cat("<td align=center>", '<img src="Box_PE.png" width=500 height=500>', lines$plotly_div,'</td></tr></table>\n', file = htmloutfile, append = TRUE);
     
     
     # Log Fold Data
@@ -1002,3 +1064,14 @@
     "<br><a href=#>TOP</a>",
     file = htmloutfile, append = TRUE);
 cat("</body></html>\n", file = htmloutfile, append = TRUE);
+
+
+#===============================================================================
+# Add masked-javascripts tags to HTML file in the head and end
+#===============================================================================
+
+htmllines <- readLines(htmloutfile)
+htmllines[1] <- paste('<html>\n<head>\n', paste(prescripts, collapse='\n'), '\n</head>\n<body>')
+cat(paste(htmllines, collapse='\n'), file = htmloutfile)
+cat('\n', paste(postscripts, collapse='\n'), "\n",
+    "</body>\n</html>\n", file = htmloutfile, append = TRUE);

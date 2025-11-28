# Set working directory
setwd("Data/")

# Packages
library(sf)
library(sp)
library(spdep)
library(tidyverse)
library(osmdata)
library(readxl)
library(gstat)
library(spatialreg)
library(tmap)

#-------------------------
# 1. Carico confini comuni PT-PO
#-------------------------
confini <- st_read("comuni-istat/Com01012025_WGS84.shp")
toscana <- confini[confini$COD_REG==9,]

#-------------------------
# 2. Carico vivai da Overpass
#-------------------------
vivai <- st_read("vivai.geojson", quiet = TRUE)
vivai <- st_transform(vivai, st_crs(toscana))

# Assegno ogni vivaio al comune
vivai_toscana <- st_join(vivai, toscana, join = st_intersects)
vivai_toscana <- vivai_toscana[!is.na(vivai_toscana$COD_CM),]

# plot 1.
dev.new()
plot(st_geometry(toscana), col="grey90", border="grey70", lwd=0.3)
plot(st_geometry(vivai_toscana), col="darkgreen", pch=19, cex=0.5, add= TRUE)
title("Distribuzione Vivaistica in Toscana")

# plot 2.
toscana_sp <- as_Spatial(toscana)
dev.new()
plot(toscana_sp)
text(coordinates(toscana_sp), labels=toscana$PRO_COM, cex=0.5)

# plot 3.
prov_names <- data.frame(
  COD_PROV = c(45, 46, 47, 48, 49, 50, 51, 52, 53, 100),
  PROV = c("Massa-Carrara", "Lucca", "Pistoia", "Firenze", "Livorno",
           "Pisa", "Arezzo", "Siena", "Grosseto", "Prato"))

toscana <- merge(toscana, prov_names, by="COD_PROV", all.x=TRUE)

province_border <- toscana |> group_by(PROV) |> summarise(geometry = st_union(geometry))

dev.new()
plot(st_geometry(toscana), col="grey90", border="grey70", lwd=0.3)
plot(st_geometry(province_border), border="darkgreen", lwd=2, add=TRUE)
centers <- st_centroid(province_border)
text(st_coordinates(centers), labels=province_border$PROV, col="black", cex=0.8, font=2,srt=15)

#-------------------------
# 3. Calcolo densità vivai per comune
#-------------------------
viv_com <- st_join(vivai, toscana, join = st_intersects)
viv_com <- viv_com %>% select(PRO_COM=PRO_COM, COMUNE=COMUNE, geometry)
viv_count <- viv_com %>% group_by(PRO_COM, COMUNE) %>% summarise(n=n(), .groups="drop")
viv_count_tbl <- st_drop_geometry(viv_count)

toscana <- left_join(toscana, viv_count_tbl %>% select(PRO_COM, n), by = "PRO_COM")
toscana$n[is.na(toscana$n)] <- 0

toscana$area_km2 <- as.numeric(st_area(toscana)) / 1e6
toscana$dens_viv <- toscana$n / toscana$area_km2

# plot delle densità di vivai per km2 nei comuni della Toscana
dev.new()
plot(toscana["dens_viv"], main = "Densità vivai (n/km2)")

# plot per quantili per evitare dominanza degli outlier
dev.new()
plot(
  toscana["dens_viv"], 
  main = "Densità Vivai (Classificazione per Quantili)",
  breaks = "quantile", # Usa i quantili per definire le classi
  nbreaks = 8,          # Aumenta il numero di classi (es. 8)
  pal = hcl.colors(8, "Rocket", rev = TRUE) # Usa una palette diversa
)

# oppure log transform
# Applica la trasformazione log(dens_viv + 1)
toscana$log_dens_viv <- log(toscana$dens_viv + 1)
dev.new()
plot(
  toscana["log_dens_viv"], 
  main = "Densità Vivai (Trasformazione Logaritmica - Quantili)",
  breaks = "quantile", # Metodo di classificazione
  nbreaks = 7,         # Il numero di classi è 7
  pal = hcl.colors(7, "Reds", rev = TRUE)
)

#-------------------------
# 4. Matrice spaziale (k-NN)
#-------------------------
toscana_sp <- as_Spatial(toscana)
coords1 <- coordinates(toscana_sp)


# poly2nb
toscana_nb <- poly2nb(toscana_sp)
summary(toscana_nb)
toscana_sp@data

# lag > 1
toscana_nb_lag <- nblag(toscana_nb,maxlag = 5)

dev.new()
par(mfrow=c(2,3))
for (i in 1:5){
  plot(st_geometry(toscana),col="gray")
  plot(toscana_nb_lag[[i]], coords1, add=TRUE, col=i)
  title(paste("Lag order", i))
}

# k-nearest neighbors
dev.new()
par(mfrow=c(2,3))
for (i in 1:5){
  col.knn <- knearneigh(coords1, k=i) # creo il mio oggetto e gli dico quanti vicini trovare
  plot(toscana_sp, border="grey")
  toscana_sp.nb<-knn2nb(col.knn) # trasformo in una matrice di vicinanza come prima con la funzione `knn2nb`
  plot(toscana_sp.nb, coords1, add=TRUE)
  title(paste("n neighbors",i))
}

## Matrice with KNN = 4
# coords <- st_coordinates(st_centroid(toscana))
nb_knn <- knn2nb(knearneigh(coords1, k = 4))
lw_w <- nb2listw(nb_knn, style="W", zero.policy = TRUE)
summary(sapply(lw_w$weights, sum))

#-------------------------
# 5. Moran globale e locale sulla densità vivai
#-------------------------
moran.test(toscana$dens_viv, lw_w)
local_moran <- localmoran(toscana$dens_viv, lw_w)

# Assegno quadranti e significatività
quadr <- attr(local_moran, "quadr")[, "mean"]
pval <- local_moran[, "Pr(z != E(Ii))"]
sig <- pval < 0.05
toscana$lisa_class <- factor(ifelse(sig, as.character(quadr), "Not significant"),
                          levels = c("High-High","Low-Low","High-Low","Low-High",
                                     "Not significant"))

# local Moran plot
Ii <- local_moran[, "Ii"]
brks <- c(-1, 0, 0.5, 1, 1.5, 2, 3)
cols <- grey((length(brks):2) / length(brks))
dev.new()
plot(st_geometry(toscana), col = cols[findInterval(Ii, brks, all.inside = TRUE)])
title(main = "Local Moran")
legend("bottomleft",legend = c("under 0", "0 - 0.5", "0.5 - 1",
                               "1 - 1.5", "1.5 - 2", "over 2"),fill = cols, bty="n")

#-------------------------
# 6. Regressione OLS
#-------------------------

ols_base <- lm(dens_viv ~ 1, data = toscana)
summary(ols_base)

lm.morantest(ols_base, lw_w)

# Senza covariate, la densità dei vivai è correlata tra vicini 
# (valore positivo di Moran I), ed in maniera molto significativa.
# Questo indica che sembra esserci una forte struttura spaziale da correggere 
# con un modello Spatial Lag o Error.

## Aggiungo covariate

# 1. Altitudine: https://www.istat.it/classificazione/principali-statistiche-geografiche-sui-comuni/ 
altitudine <- read_excel("Elab_Altimetrie_DEM.xlsx")

# join on Pistoia:
# correzione Abetone e San Marcello per il Join:
toscana$PRO_COM[toscana$COMUNE == "Abetone Cutigliano"] <- 47001
toscana$PRO_COM[toscana$COMUNE == "San Marcello Piteglio"] <- 47019

toscana <- left_join(
  toscana, 
  altitudine %>% select(PRO_COM, MEDIA), 
  by = c("PRO_COM" = "PRO_COM")
)
names(toscana)[names(toscana) == 'MEDIA'] <- 'alt_mean'

# uniamo altitudine comuni prima di fusione Abetone/Cutigliano e San Marcello/Piteglio
toscana$alt_mean[toscana$COMUNE == "Abetone Cutigliano"] <- altitudine %>%
  filter(PRO_COM %in% c(47001, 47004)) %>%
  pull(MEDIA) %>%
  mean(na.rm = TRUE)

toscana$alt_mean[toscana$COMUNE == "San Marcello Piteglio"] <- altitudine %>%
  filter(PRO_COM %in% c(47018, 47019)) %>%
  pull(MEDIA) %>%
  mean(na.rm = TRUE)

toscana$PRO_COM[toscana$COMUNE == "Abetone Cutigliano"] <- 47023
toscana$PRO_COM[toscana$COMUNE == "San Marcello Piteglio"] <- 47024

# 2. Densità Abitativa: https://demo.istat.it/app/?i=POS 
residents <- read_excel("pop.xlsx", col_names = TRUE)
residents = residents %>% select(`Codice comune`,Comune,Totale)

toscana <- left_join(
  toscana,
  residents %>% select(`Codice comune`,Totale),
  by = c("PRO_COM_T" = "Codice comune")
)
names(toscana)[names(toscana) == 'Totale'] <- 'pop'

toscana$pop_dens = toscana$pop/toscana$area_km2

# 3. Turismo https://esploradati.istat.it/databrowser/#/it/dw/categories/IT1,Z0700SER,1.0/SER_TOURISM

turisti <- read_excel("turisti.xlsx",sheet="2024",col_names = TRUE)
turisti <- turisti[(turisti$`Cod. Prov.`=="047" | turisti$`Cod. Reg`=="090") & !is.na(turisti$`Cod. Reg`) ,]
turisti$turi <- as.numeric(turisti$turi)

toscana <- left_join(
  toscana,
  turisti %>% select("Cod. Istat","Comune / Municipality", "turi"),
  by = c("PRO_COM_T" = "Cod. Istat")
)
toscana$turi[toscana$COMUNE== "Sambuca Pistoiese"] <- 1747
toscana$turi[toscana$COMUNE== "Ponte Buggianese"] <- 1747
toscana$turi[toscana$COMUNE== "Fosciandora"] <- 741
toscana$turi[toscana$COMUNE== "Villa Basilica"] <- 741
toscana$turi[toscana$COMUNE== "Orciano Pisano"] <- 113
toscana$turi[toscana$COMUNE== "Santa Croce sull'Arno"] <- 113
toscana$tur_dens <- toscana$turi / toscana$area_km2

# OLS con covariata turismo:
ols_reg <- lm(dens_viv ~ alt_mean + pop_dens + tur_dens, data = toscana) 
summary(ols_reg)
# Moran sui residui:
lm.morantest(ols_reg, lw_w)

#-------------------------
# 7. Modelli Spaziali
#-------------------------

lm.RStests(ols_reg, lw_w, test="all")

sar_model <- lagsarlm(
  dens_viv ~ alt_mean + pop_dens + tur_dens,
  data = toscana,
  listw = lw_w,
  zero.policy = TRUE
)
summary(sar_model)

sem_model <- errorsarlm(
  dens_viv ~ alt_mean + pop_dens + tur_dens,
  data = toscana,
  listw = lw_w,
  zero.policy = TRUE
)
summary(sem_model)

sarma_model <- sacsarlm(
  dens_viv ~ alt_mean + pop_dens + tur_dens,
  data = toscana,
  listw = lw_w,
  type = "mixed",
  zero.policy = TRUE
)
summary(sarma_model)

# Effetti significativi: densità popolazione e turismo, perché rimangono robusti 
# anche nei modelli spaziali.
# Altitudine: puoi menzionarla come covariata “inizialmente significativa”, ma che 
# perde importanza quando consideri la dipendenza spaziale.
# Autocorrelazione spaziale: fondamentale sottolineare che un modello OLS tradizionale 
# sottostimerebbe gli errori, perché non tiene conto dei vicini. SAR/SEM corregge 
# questo e cambia le stime dei coefficienti.

#-------------------------
# 8. Aggiungo Qualità dell'Aria - Carico dati PM10 e kriging
#-------------------------
pm10 <- read_excel("pm10.xlsx")
pm10_sf <- pm10 %>%
  st_as_sf(coords = c("E", "N"), crs = 3003) %>%
  st_transform(crs = st_crs(toscana))

toscana_cent <- st_centroid(toscana)
pm10_sp <- as_Spatial(pm10_sf)
toscana_cent_sp <- as_Spatial(toscana_cent)

vg <- variogram(pm10_2024_mean ~ 1, pm10_sp)
plot(vg)
v_model <- fit.variogram(vg, model=vgm(psill=10, model="Sph", range=50000, nugget=5))
plot(vg, model=v_model)
kriged <- krige(pm10_2024_mean ~ 1, pm10_sp, toscana_cent_sp, model=v_model)
# Non converge

toscana$PM10_kriged <- kriged$var1.pred
# toscana$PM10_var <- kriged$var1.var

# IDW interpolation --- since kriging not converging
idw_res <- idw(pm10_2024_mean ~ 1, pm10_sf, toscana_cent, idp = 2)
toscana$PM10_idw <- idw_res$var1.pred

#-------------------------
# 7. Scatterplot e correlazione
#-------------------------
ggplot(toscana, aes(x = dens_viv, y = PM10_idw)) +
  geom_point() +
  geom_smooth(method = "lm") +
  labs(x = "Densità Vivai (n/km²)", y = "PM10 stimato (µg/m³)",
       title = "Correlazione tra Vivai e PM10")

cor(toscana$dens_viv, toscana$PM10_idw, use = "complete.obs")

# Regressione semplice
lm_pm10_vivai <- lm(PM10_idw ~ dens_viv + pop_dens, data = toscana)
summary(lm_pm10_vivai)
lm.morantest(lm_pm10_vivai, lw_w)

#-------------------------
# 8. Mappa finale
#-------------------------
dev.new()
tm_shape(toscana) +
  tm_polygons("PM10_idw", palette = "YlOrRd", title = "PM10 stimato") +
  tm_bubbles("dens_viv", col = "blue", scale = 1, title.size = "Densità vivai")

# SAR spaziale
# sar_pm10 <- lagsarlm(PM10_idw ~ dens_viv + pop_dens + tur_dens + alt_mean, data = toscana, listw = lw_w, zero.policy = TRUE)
sar_pm10 <- lagsarlm(PM10_idw ~ dens_viv + pop_dens, data = toscana, listw = lw_w, zero.policy = TRUE)
summary(sar_pm10)

sem_pm10 <- errorsarlm(PM10_idw ~ dens_viv + pop_dens, data = toscana, listw = lw_w, zero.policy = TRUE)
summary(sem_pm10)

# Effetto della densità vivai (dens) sul PM10 stimato con IDW:
#   Il coefficiente è 0.0908, ma il p-value = 0.5317, quindi non significativo.
# In altre parole, secondo questo modello spaziale, la densità dei vivai non sembra 
# avere alcun effetto rilevante sui valori di PM10 stimati tramite IDW.
# Effetto spaziale (Rho = 0.9198):
#   Il parametro di lag spaziale è molto alto e altamente significativo, con p-value 
# praticamente zero.
# Questo significa che i valori di PM10 sono fortemente autocorrelati spazialmente: 
#   i comuni confinanti hanno valori simili, indipendentemente dalla densità dei vivai.
# Conclusione pratica:
#   Anche se inserisci dens nel modello, non contribuisce a spiegare PM10: 
#   l’autocorrelazione spaziale domina completamente la variabilità.
# Quindi non ha senso includere la densità dei vivai come covariata predittiva per 
# PM10 in questa analisi. Puoi comunque riportare l’analisi per completezza, ma 
# evidenzia che non è significativa.


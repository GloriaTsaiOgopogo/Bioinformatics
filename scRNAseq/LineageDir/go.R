G3=readRDS('G3.RDS')
G4=readRDS('G4.RDS')

dim(G3)
dim(G4)

DATA=cbind(G3,G4)

rm(G3)
rm(G4)
gc()


library(Seurat)

pbmc <- CreateSeuratObject(counts = DATA, project = "pbmc3k", min.cells = 0, min.features = 0)
pbmc <- NormalizeData(pbmc, normalization.method = "LogNormalize", scale.factor = 10000)

pbmc <- FindVariableFeatures(pbmc, selection.method = "vst", nfeatures = 5000)

all.genes <- rownames(pbmc)
pbmc <- ScaleData(pbmc, features = all.genes)



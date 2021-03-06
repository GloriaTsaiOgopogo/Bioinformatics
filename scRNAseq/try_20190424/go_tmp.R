library('Seurat')
library(dplyr)
library(Matrix)

source('https://raw.githubusercontent.com/jumphone/Bioinformatics/master/scRNAseq/try_20190424/SCC.R')


load('Seurat_EXP_cluster.Robj')

pbmc=EXP_cluster
used=which(as.numeric(as.character(EXP_cluster@ident)) %in% c(2,9,14,17,19,23))

pbmc.raw.data=getSeuratRAW(pbmc@raw.data,pbmc@scale.data)[,used]

############
tmp=CreateSeuratObject(raw.data = pbmc.raw.data, min.cells = 0, min.genes = 0, project = "10X_PBMC")
mito.genes <- grep(pattern = "^Mt", x = rownames(x = tmp@data), value = TRUE)
percent.mito <- colSums(tmp@data[mito.genes, ]) / colSums(tmp@data)
tmp <- AddMetaData(object = tmp, metadata = percent.mito, col.name = "percent.mito")
tmp <- NormalizeData(object = tmp, normalization.method = "LogNormalize",  scale.factor = 10000)
tmp <- FindVariableGenes(object = tmp,do.plot=FALSE, mean.function = ExpMean, dispersion.function = LogVMR, x.low.cutoff = 0.0125, x.high.cutoff = 3, y.cutoff = 0.5)
length(x = tmp@var.genes)
tmp <- ScaleData(object = tmp, vars.to.regress = c("nUMI",'percent.mito'), genes.use = tmp@var.genes)
#################

pbmc.data=as.matrix(tmp@scale.data)

used_gene=tmp@var.genes
pbmc.raw.data=pbmc.raw.data[which(rownames(pbmc.raw.data) %in% used_gene),]
pbmc.data=pbmc.data[which(rownames(pbmc.data) %in% used_gene),]

source('https://raw.githubusercontent.com/jumphone/BEER/master/BEER.R')
ONE=.data2one(pbmc.raw.data, used_gene, CPU=4, PCNUM=50, SEED=123,  PP=30)
saveRDS(ONE,file='ONE.RDS')

OUT=getBIN(ONE)
BIN=OUT$BIN
BINTAG=OUT$TAG
saveRDS(BIN,file='BIN.RDS')
saveRDS(BINTAG,file='BINTAG.RDS')




pbmc@meta.data$bin=rep(NA,length(pbmc@ident))
pbmc@meta.data$bin[used]=BINTAG
pdf('1ID.pdf',width=12,height=10)
DimPlot(pbmc,group.by='bin',reduction.use='tsne',do.label=T)
dev.off()

LR=read.table('RL_mouse.txt',header=T,sep='\t')
EXP=pbmc.data

MEAN=getMEAN(EXP, LR)
saveRDS(MEAN,file='MEAN.RDS')
    
PMAT=getPMAT(EXP, LR, BIN, MEAN)
saveRDS(PMAT,file='PMAT.RDS')

CMAT=getCMAT(EXP,LR,PMAT,PRO=TRUE)
saveRDS(CMAT,file='CMAT.RDS')

pdf('2HEAT.pdf',width=15,height=13)
library('gplots')
heatmap.2(CMAT,scale=c("none"),dendrogram='none',Colv=F,Rowv=F,trace='none',
  col=colorRampPalette(c('blue3','grey95','red3')) ,margins=c(10,15))
dev.off()

OUT=getPAIR(CMAT)
PAIR=OUT$PAIR
SCORE=OUT$SCORE
RANK=OUT$RANK
saveRDS(PAIR,file='PAIR.RDS')

VEC=pbmc@dr$tsne@cell.embeddings
pdf('3CPlot.pdf',width=12,height=10)
CPlot(VEC,PAIR[1:100,],pbmc@meta.data$bin)
dev.off()

CC=as.numeric(as.character(pbmc@ident))
TAG=rep('NA',length(pbmc@ident))
TAG[CC %in% c(23,19)]='Normal_Schwann'
TAG[CC %in% c(9,2,14,17)]='Tumor'
TAG[CC %in% c(22,20,24)]='Tumor_PlotCenter'
TAG[CC %in% c(15,25,30)]='Endothelial'
TAG[CC %in% c(0,3,10,13,8,16,11,28,18)]='Fibroblast'
TAG[CC %in% c(1,4,5,6,7,21)]='Macrophage'
TAG[CC %in% c(12,27,26)]='T_Cell'
TAG[CC %in% c(29)]='B_Cell'

ORITAG=TAG
NET=getNET(PAIR, BINTAG,ORITAG[used] )
write.table(NET,file='NET.txt',sep='\t',row.names=F,col.names=T,quote=F)
   
CN=getCN(NET)
pdf('4DPlot.pdf',width=10,height=5)
DP=DPlot(NET, CN, COL=2)
dev.off()

SIG_INDEX=which(DP<0.05)
SIG_PAIR=names(SIG_INDEX)

pdf('5LPlot.pdf',width=20,height=20)
RCN=trunc(sqrt(length(SIG_PAIR))+1)
par(mfrow=c(RCN,RCN))
i=1
while(i<= length(SIG_PAIR) ){
    this_pair=SIG_PAIR[i]
    LT=unlist(strsplit(this_pair, "_to_"))[1]
    RT=unlist(strsplit(this_pair, "_to_"))[2]
    LP=LPlot(LT, RT, NET, PMAT,MAIN=as.character(SIG_INDEX[i]),SEED=123)    
    colnames(LP)=paste0(c('Lexp','Rexp'),'_',c(LT,RT))
    write.table(LP,file=paste0(as.character(SIG_INDEX[i]),'.tsv'),row.names=T,col.names=T,sep='\t',quote=F)
    print(i)
    i=i+1}
dev.off()


ORITAG=groupTAG(BINTAG,LT='7',RT='98',LC='7',RC='98')
NET=getNET(PAIR, BINTAG,ORITAG )
LPlot(LT='7', RT='98', NET, PMAT,MAIN=as.character(SIG_INDEX[i]),SEED=123)    


ORITAG=groupTAG(BINTAG,LT='1',RT='2',LC='1',RC='2')
NET=getNET(PAIR, BINTAG,ORITAG )
LPlot(LT='1', RT='2', NET, PMAT,MAIN=as.character(SIG_INDEX[i]),SEED=123)    





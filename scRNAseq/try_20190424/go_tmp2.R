source('https://raw.githubusercontent.com/jumphone/Bioinformatics/master/scRNAseq/try_20190424/SCC.R')


library(Seurat)
library(dplyr)
library(Matrix)
load('HDN_Wkspace.RData')

pbmc=tumor2
pbmc.raw.data=as.matrix(pbmc@raw.data[,which(colnames(pbmc@raw.data) %in% colnames(pbmc@scale.data))])
pbmc.data=as.matrix(pbmc@scale.data)
used_gene=rownames(pbmc.data)

    source('https://raw.githubusercontent.com/jumphone/BEER/master/BEER.R')  
    #---------------------------------------
    # For Seurat==3.0, please use:
    # source('https://raw.githubusercontent.com/jumphone/BEER/master/BEER_Seurat3.R')
    #---------------------------------------
    
    ONE=.data2one(pbmc.raw.data, used_gene, CPU=4, PCNUM=50, SEED=123,  PP=30)
    saveRDS(ONE,file='ONE.RDS')
    
    OUT=getBIN(ONE)
    BIN=OUT$BIN
    BINTAG=OUT$TAG
    saveRDS(BIN,file='BIN.RDS')
    saveRDS(BINTAG,file='BINTAG.RDS')



EXP=pbmc.data
LR=read.table('RL_mouse.txt',header=T,sep='\t')

 
    MEAN=getMEAN(EXP, LR)
    saveRDS(MEAN,file='MEAN.RDS')
        
    PMAT=getPMAT(EXP, LR, BIN, MEAN)
    saveRDS(PMAT,file='PMAT.RDS')
    

OOO=.data2one(t(PMAT), colnames(PMAT), CPU=4, PCNUM=50, SEED=123,  PP=5)


CLUST=getCLUST(order(OOO), DIST, CCUT=0.7, SHOW=T)



#heatmap.2(DIST[order(OOO)[length(order(OOO)):1],order(OOO)],scale='none',dendrogram='none',Colv=F,Rowv=F,trace='none',
#            col=colorRampPalette(c('blue3','grey95','red3')), ColSideColors=RC ,RowSideColors=RC[length(out$colInd):1] ,margins=c(5,5), labRow='',labCol='') 
        



OUT=getPmatHEAT(PMAT,SHOW=T)
HEAT=OUT$HEAT
DIST=OUT$DIST



CLUST=getCLUST(HEAT$colInd , DIST, CCUT=0.7, SHOW=T)


MLR=getMLR(CLUST, LR, PMAT)
LR=MLR[,c(1:2)]




CMAT=getCMAT(EXP,LR,PMAT,BI=T)
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

#---- !!! Changed in Seurat 3.0 !!! ----
VEC=pbmc@dr$umap@cell.embeddings
#--------------------------------------- 
# For Seurat 3.0, please use:
# VEC=pbmc@reductions$tsne@cell.embeddings
#---------------------------------------

pdf('3CPlot.pdf',width=12,height=10)
CPlot(VEC,PAIR[1:200,],BINTAG)
dev.off()


ORITAG=as.character(pbmc@ident)
ORITAG[which(ORITAG=='Pericyte/\nFibroblast')]='Pericyte Fibroblast'

NET=getNET(PAIR, BINTAG,ORITAG )
write.table(NET,file='NET.txt',sep='\t',row.names=F,col.names=T,quote=F)
   
CN=getCN(NET)
pdf('4DPlot.pdf',width=20,height=20)
DP=DPlot(NET, CN, COL=3)
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
    LP=LPlot(LT, RT, NET, PMAT=PMAT,LR=LR,MAIN=SIG_INDEX[i],SEED=12345, PCUT=0.05)
    colnames(LP)=paste0(c('Lexp','Rexp'),'_',c(LT,RT))
    write.table(LP,file=paste0(as.character(SIG_INDEX[i]),'.tsv'),row.names=T,col.names=T,sep='\t',quote=F)
    print(i)
    i=i+1}
dev.off()
















source('https://raw.githubusercontent.com/jumphone/BEER/master/BEER.R')
ONE=.data2one(pbmc.raw.data, used_gene, CPU=4, PCNUM=50, SEED=123,  PP=30)
#ONE=readRDS('ONE.RDS')


OUT=getBIN(ONE)
BIN=OUT$BIN
BINTAG=OUT$TAG

pbmc@meta.data$bin=BINTAG
png('ID.png',width=1200,height=1000)
DimPlot(pbmc,group.by='bin',reduction.use='umap',do.label=T)
dev.off()



EXP=pbmc.data
LR=read.table('RL_mouse.txt',header=T,sep='\t')

MEAN=getMEAN(EXP, LR)
saveRDS(MEAN,file='MEAN.RDS')
    
PMAT=getPMAT(EXP, LR, BIN, MEAN)
saveRDS(PMAT,file='PMAT.RDS')

################################
DIST=cor(t(PMAT),method='spearman')
library('gplots')
heatmap.2(DIST,scale='none',dendrogram='both',Colv=T,Rowv=T,trace='none',
  col=colorRampPalette(c('blue3','grey95','red3')) ,margins=c(10,15), labRow='',labCol='')


out=heatmap.2(DIST,scale='none',dendrogram='both',Colv=T,Rowv=T,trace='none',
  col=colorRampPalette(c('blue3','grey95','red3')) ,margins=c(10,15), labRow='',labCol='')

OUT=getPmatHEAT(PMAT,SHOW=T)
HEAT=OUT$HEAT
DIST=OUT$DIST

CLUST=getCLUST(HEAT, DIST, CCUT=0.7, SHOW=T)


MLR=getMLR(CLUST, LR, PMAT)
LR=MLR[,c(1:2)]


CMAT=getCMAT(EXP,LR,PMAT,BI=T)
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

#---- !!! Changed in Seurat 3.0 !!! ----
VEC=pbmc@dr$umap@cell.embeddings
#--------------------------------------- 
# For Seurat 3.0, please use:
# VEC=pbmc@reductions$tsne@cell.embeddings
#---------------------------------------

pdf('3CPlot.pdf',width=12,height=10)
CPlot(VEC,PAIR[1:200,],BINTAG)
dev.off()


ORITAG=as.character(pbmc@ident)
ORITAG[which(ORITAG=='Pericyte/\nFibroblast')]='Pericyte Fibroblast'

NET=getNET(PAIR, BINTAG,ORITAG )
write.table(NET,file='NET.txt',sep='\t',row.names=F,col.names=T,quote=F)
   
CN=getCN(NET)
pdf('4DPlot.pdf',width=20,height=20)
DP=DPlot(NET, CN, COL=3)
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
    LP=LPlot(LT, RT, NET, PMAT=PMAT,LR=LR,MAIN=SIG_INDEX[i],SEED=12345, PCUT=0.05)
    colnames(LP)=paste0(c('Lexp','Rexp'),'_',c(LT,RT))
    write.table(LP,file=paste0(as.character(SIG_INDEX[i]),'.tsv'),row.names=T,col.names=T,sep='\t',quote=F)
    print(i)
    i=i+1}
dev.off()









































MPMAT=PMAT[1:length(unique(TAG)),]
rownames(MPMAT)=as.character(c(1:max(TAG)))
MPMAT=MPMAT*0
i=1
while(i<=nrow(MPMAT)){
this_gene=names(which(TAG==i))
this_row=which(rownames(PMAT)%in% this_gene)
if(length(which(TAG==i))>1){
MPMAT[i,]=apply(PMAT[this_row,],2,mean)}else{
MPMAT[i,]=PMAT[this_row,]}
i=i+1}

MLR=c()
i=1
while(i<=nrow(LR)){
this_l=as.character(LR[i,1])
this_r=as.character(LR[i,2])
if(this_l %in% rownames(PMAT) & this_r %in% rownames(PMAT)){
    M_this_l=TAG[which(names(TAG)==this_l)]
    M_this_r=TAG[which(names(TAG)==this_r)]
    MLR=cbind(MLR,c(M_this_l,M_this_r))
    }
i=i+1
}

MLR=t(MLR)
colnames(MLR)=c('L','R')
MLR=unique(MLR)






################################

MCMAT=getCMAT(EXP,LR=MLR,PMAT=MPMAT,BI=T)
library('gplots')
heatmap.2(MCMAT,scale=c("none"),dendrogram='none',Colv=F,Rowv=F,trace='none',
  col=colorRampPalette(c('blue3','grey95','red3')) ,margins=c(10,15))

OUT=getPAIR(MCMAT)
PAIR=OUT$PAIR
SCORE=OUT$SCORE
RANK=OUT$RANK
VEC=pbmc@dr$umap@cell.embeddings
CPlot(VEC,PAIR[1:200,],BINTAG)

ORITAG=as.character(pbmc@ident)
ORITAG[which(ORITAG=='Pericyte/\nFibroblast')]='Pericyte Fibroblast'

NET=getNET(PAIR, BINTAG,ORITAG )

DP=DPlot(NET, CN, COL=4)



SIG_INDEX=which(DP<0.05)
SIG_PAIR=names(SIG_INDEX)

RCN=trunc(sqrt(length(SIG_PAIR))+1)
par(mfrow=c(RCN,RCN))
i=1
while(i<= length(SIG_PAIR) ){
    this_pair=SIG_PAIR[i]
    LT=unlist(strsplit(this_pair, "_to_"))[1]
    RT=unlist(strsplit(this_pair, "_to_"))[2]
    LP=LPlot(LT, RT, NET, PMAT=MPMAT,LR=MLR,MAIN=SIG_INDEX[i],SEED=123)    
    colnames(LP)=paste0(c('Lexp','Rexp'),'_',c(LT,RT))
    write.table(LP,file=paste0(as.character(SIG_INDEX[i]),'.tsv'),row.names=T,col.names=T,sep='\t',quote=F)
    print(i)
    i=i+1}

 


LI=48
RI=27
LI=12
RI=16
LI=72
RI=9

this_l=which(TAG==LI)
this_r=which(TAG==RI)
this_ln=as.character(LR[which(LR[,1]%in% names(this_l) & LR[,2] %in% names(this_r)),1])
this_rn=as.character(LR[which(LR[,1]%in% names(this_l) & LR[,2] %in% names(this_r)),2])
this_ln
this_rn
LP=LPlot('Proliferating Cells', 'Microglia', NET, PMAT=PMAT,LR=LR,SEED=123)   
LP[which(rownames(LP)==paste0(as.character(this_ln),'_',as.character(this_rn))),]

LP=LPlot('Microglia', 'Proliferating Cells', NET, PMAT=MPMAT,LR=MLR,SEED=123)   



###################

CMAT=getCMAT(EXP,LR,PMAT,BI=T)
saveRDS(CMAT,file='CMAT.RDS')


plot(as.numeric(CMAT), as.numeric(t(CMAT)))





pdf('2HEAT.pdf',width=15,height=13)
library('gplots')
heatmap.2(CMAT,scale=c("none"),dendrogram='none',Colv=F,Rowv=F,trace='none',
  col=colorRampPalette(c('blue3','grey95','red3')) ,margins=c(10,15))
dev.off()




BMAT=CMAT+t(CMAT)
heatmap.2(BMAT,scale=c("none"),dendrogram='none',Colv=F,Rowv=F,trace='none',
  col=colorRampPalette(c('blue3','grey95','red3')) ,margins=c(10,15))



OUT=getPAIR(CMAT)
PAIR=OUT$PAIR
SCORE=OUT$SCORE
RANK=OUT$RANK
saveRDS(PAIR,file='PAIR.RDS')

#---- !!! Changed in Seurat 3.0 !!! ----
VEC=pbmc@dr$tsne@cell.embeddings
#--------------------------------------- 
# For Seurat 3.0, please use:
# VEC=pbmc@reductions$tsne@cell.embeddings
#---------------------------------------

pdf('3CPlot.pdf',width=12,height=10)
CPlot(VEC,PAIR[1:200,],BINTAG)
dev.off()


ORITAG=as.character(pbmc@ident)
ORITAG[which(ORITAG=='Pericyte/\nFibroblast')]='Pericyte Fibroblast'

NET=getNET(PAIR[1:200,], BINTAG,ORITAG )
write.table(NET,file='NET.txt',sep='\t',row.names=F,col.names=T,quote=F)
   
CN=getCN(NET)
pdf('4DPlot.pdf',width=20,height=20)
DP=DPlot(NET, CN, COL=3)
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
    c  
    colnames(LP)=paste0(c('Lexp','Rexp'),'_',c(LT,RT))
    write.table(LP,file=paste0(as.character(SIG_INDEX[i]),'.tsv'),row.names=T,col.names=T,sep='\t',quote=F)
    print(i)
    i=i+1}
dev.off()




















getCMAT <- function(EXP, LR, PMAT, BI=FALSE){
    
    GENE=rownames(EXP)
    CMAT=PMAT[c(1:ncol(PMAT)),]*0
    rownames(CMAT)=colnames(CMAT)
    rownames(CMAT)=paste0('L_',rownames(CMAT))
    colnames(CMAT)=paste0('R_',colnames(CMAT))
    
    TP=apply(PMAT,1,sum)
    
    
    i=1
    #i=956
    while(i<=nrow(LR)){

        this_l=as.character(LR[i,1])
        this_r=as.character(LR[i,2])
        #########################
        

        
        if(this_l %in% GENE & this_r %in% GENE){
            
            #########
            this_l_rs=as.character(LR[which(LR[,1]==this_l),2])
            this_r_ls=as.character(LR[which(LR[,2]==this_r),1])
            
            this_l_rs=this_l_rs[which(this_l_rs %in% GENE)]
            this_r_ls=this_r_ls[which(this_r_ls %in% GENE)]
            
            this_l_rs_ratio=c()
            this_r_ls_ratio=c()
            
            for(one in this_l_rs){this_l_rs_ratio=c(this_l_rs_ratio,TP[which(names(TP)==one)])}
            for(one in this_r_ls){this_r_ls_ratio=c(this_r_ls_ratio,TP[which(names(TP)==one)])}
            this_l_rs_ratio=this_l_rs_ratio/sum(this_l_rs_ratio)
            this_r_ls_ratio=this_r_ls_ratio/sum(this_r_ls_ratio)
            
            #############
                     
            this_l_index=which(rownames(PMAT)==this_l)
            this_r_index=which(rownames(PMAT)==this_r)
            this_l_bin_index=1
            while(this_l_bin_index<=nrow(CMAT)){
                this_r_bin_index=1
                while(this_r_bin_index<=ncol(CMAT)){
                    if(this_l_bin_index==this_r_bin_index){this_add=0}else{
                    
                    l_bin_base = PMAT[this_l_index,this_l_bin_index] - PMAT[this_r_index,this_l_bin_index]
                    r_bin_base = PMAT[this_r_index,this_r_bin_index] - PMAT[this_l_index,this_r_bin_index]
                        
                    ######################  
                    if(BI==FALSE){
                        this_add= l_bin_base + r_bin_base 
                    }else{
                        if(l_bin_base<=0 | r_bin_base<=0){
                            this_add=0}else{
                            
                            p_l_bin_base=(l_bin_base * this_l_rs_ratio)[which(names(this_l_rs_ratio)==this_r)]
                            p_r_bin_base=(r_bin_base * this_r_ls_ratio)[which(names(this_r_ls_ratio)==this_l)]
                            
                            
                            #this_add= (l_bin_base + r_bin_base)*( min(l_bin_base,r_bin_base)/max(l_bin_base,r_bin_base) )
                            this_add= min(p_l_bin_base, p_r_bin_base)
                            }
                         }
                    ######################  
                        
                    }
                    CMAT[this_l_bin_index,this_r_bin_index]=CMAT[this_l_bin_index,this_r_bin_index]+ this_add
                    this_r_bin_index=this_r_bin_index+1
                    }      
                this_l_bin_index=this_l_bin_index+1
                } 
             }
        if(i%%10==1){print(i)}
        i=i+1}

    CMAT=as.matrix(CMAT)
    return(CMAT)
    }

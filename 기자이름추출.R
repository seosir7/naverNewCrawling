
#처음 한번만 실행
#install.packages('stringr')

#껐다 켰을때 매번 실행
library(stringr)

#데이터 불러오기
newscrawling <- read.csv(file.choose(),header=T) 

#정규표현식 사용하여 기자이름 찾고 원하는 형식으로 바꿔줌
reporternames <- str_extract_all(newscrawling$텍스트,"[가-히]{3} [기][자]")
reporternames <- as.matrix(reporternames)
reporternames2 <- as.data.frame(reporternames)

#,표시때문에 생기는 에러를 제거
reporternames2$V1 <- vapply(reporternames2$V1, paste, collapse = ", ", character(1L))

#기자이름과 원데이터 합치기
crawlingdata <- cbind(newscrawling,reporternames2)
head(crawlingdata)

#8번 컬럼의 이름을 기자로 변경
names(crawlingdata)[8]<-'기자'

#완성된 파일을 csv로 저장
write.csv(crawlingdata,file='2019모비스(10월13-3월22).csv',row.names = F)



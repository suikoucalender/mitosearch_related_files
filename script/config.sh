# ------------

#projectのPATH
#mitosearch_path=/home/yoshitake/mitosearch/Mitosearch
mitosearch_path=/suikou/download9-v251/mitosearch/mitosearch/Mitosearch
#mitosearch_dev_path=/home/yoshitake/mitosearch_dev/mitosearch/Mitosearch

# 作業ディレクトリを指定
#workdir=/mnt/n3data/mitosearch_related_files
#workdir=/suikou/download9-v251/mitosearch/mitosearch/Mitosearch
#sdirは呼び出し元のファイルで既に定義されているはず(scriptフォルダになっているはず)
workdir="$sdir"/../

# singularityのPATH
#singularity_path=/home/yoshitake/tool/singularity-3.5.2/bin/singularity
singularity_path=`which singularity`

# 各サンプルの一時ファイルを配置するディレクトリを格納するディレクトリ
tmpdir=/tmp

# blastnのPATH
#blastn_path="${workdir}"/script/blastn
blastn_path=`which blastn`

# MitoFishのBlast DBファイル
#blastdb="${workdir}"/db/complete_partial_mitogenomes.fa
blastdb="${workdir}"/db/database.fasta

# 魚種和名ファイルのPath
#fishname_ja_Path="${workdir}"/db/20210718_JAFList.xlsx

# metadataを格納しているディレクトリ
metadataDir="$mitosearch_path"/data/fish
metadataDir_dev="$mitosearch_dev_path"/data/fish

# Scriptが配置されているディレクトリ
scriptdir="${workdir}"/script

# FASTQデータを配置するディレクトリ
edna_file="${workdir}/fastq"

# inputファイルの出力先ディレクトリ
#outputFileDirPath=${workdir}/inputFiles

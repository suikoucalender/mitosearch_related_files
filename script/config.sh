# ------------

# 作業ディレクトリを指定
workdir=/mnt/n3data/mitosearch_related_files

#projectのPATH
mitosearch_path=/home/yoshitake/mitosearch/Mitosearch
mitosearch_dev_path=/home/yoshitake/mitosearch_dev/mitosearch/Mitosearch

# singularityのPATH
singularity_path=/home/yoshitake/tool/singularity-3.5.2/bin/singularity

# 各サンプルの一時ファイルを配置するディレクトリを格納するディレクトリ
tmpdir=/tmp

# blastnのPATH
blastn_path="${workdir}"/script/blastn

# MitoFishのBlast DBファイル
#blastdb="${workdir}"/db/complete_partial_mitogenomes.fa
blastdb="${workdir}"/db/database.fasta

# 魚種和名ファイルのPath
fishname_ja_Path="${workdir}"/db/20210718_JAFList.xlsx

# inputFileを格納しているディレクトリ
mitosearch_db="$mitosearch_path"/db_fish
mitosearch_dev_db="$mitosearch_dev_path"/db_fish

# metadataを格納しているディレクトリ
metadataDir="$mitosearch_path"/data/fish
metadataDir_dev="$mitosearch_dev_path"/data/fish

# Scriptが配置されているディレクトリ
scriptdir="${workdir}"/script

# FASTQデータを配置するディレクトリ
edna_file="${workdir}/fastq"

# inputファイルの出力先ディレクトリ
outputFileDirPath=${workdir}/inputFiles

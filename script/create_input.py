# coding: utf-8
import xlrd
import sys
import subprocess
import os

prefix = sys.argv[1]
outputFileDirPath = sys.argv[2]
fishname_ja_Path = sys.argv[3]
tmpDir = sys.argv[4]
inputFilePath = tmpDir + "/" + prefix + "/" + prefix + ".input.tmp"
outputFilePath = outputFileDirPath + "/" + prefix + ".input"

def main():
    # ファイルが存在しない場合は例外処理
    if not os.path.exists(inputFilePath):
        print("No input file")
        return
    
    # input.tmpファイルを開く
    inputFile = open(inputFilePath)

    # input.tmpファイルの各行をリストとして取得
    inputFileRowList = inputFile.readlines()

    # 以下の各関数ではinputファイルの改行区切りリストを関数の入力および出力としている。

    # 和名を付与した魚種組成リストを作成
    inputFileRowList_withJAname = add_ja_name(inputFileRowList)
    print(inputFileRowList_withJAname)

    # 魚種の重複を排除
    inputFileRowList_withJAname_duplicationRemoved = duplication_remove(inputFileRowList_withJAname)
    print(inputFileRowList_withJAname_duplicationRemoved)

    # 組成の中で占める割合が1%未満の種を除去
    inputFileRowList_withJAname_duplicationRemoved_minorRemoved = minor_remove(inputFileRowList_withJAname_duplicationRemoved)
    print(inputFileRowList_withJAname_duplicationRemoved_minorRemoved)

    # 100read未満のサンプルを除去および組成を百分率で表示
    inputFileRowList_withJAname_duplicationRemoved_minorRemoved_percent = calc_percent(inputFileRowList_withJAname_duplicationRemoved_minorRemoved)
    print(inputFileRowList_withJAname_duplicationRemoved_minorRemoved_percent)

    # 100read未満のサンプルは処理を終了
    if inputFileRowList_withJAname_duplicationRemoved_minorRemoved_percent == "less than 100 reads":
        return
    
    # inputファイルの書き込み
    write_inputfile(inputFileRowList_withJAname_duplicationRemoved_minorRemoved_percent)

    inputFile.close()

def add_ja_name(inputFileRowList):
    # Xlrdモジュールで和名が記載されたExcelファイルを開く
    fishname_ja_wb = xlrd.open_workbook(fishname_ja_Path)
    
    # シートを取得
    fishname_ja_sh = fishname_ja_wb.sheet_by_index(0)
    
    # 学名のリストと和名のリストを取得
    academic_nameList = fishname_ja_sh.col_values(4)
    japanese_namesList = fishname_ja_sh.col_values(3)
    
    # Excelの長さを取得
    sh_len = len(academic_nameList)

    # 和名付与済み魚種組成リスト
    inputFileRowList_withJAname = []

    for i, row in enumerate(inputFileRowList):
        # Headerを追加
        if i == 0:
            inputFileRowList_withJAname.append(row)
        # 和名に変換
        else:
            # 種名を取得
            species = row.split("\t")[0]

            # 組成量を取得
            comp = row.split("\t")[1]

            # デフォルトの和名に空文字を割り当てる
            japanese_name = ""

            # 和名リストの各行に対して検索を行い、ヒットしたものに置換
            for i in range(sh_len):   
                academic_name = academic_nameList[i].split()[:2]
                
                # 学名にマッチするものを検索
                if academic_name[0] in species and academic_name[1] in species:
                    
                    # マッチした学名に対応する和名を取得
                    japanese_name = japanese_namesList[i]
                    break
            
            # 種名のみを抽出
            species = species.split("|")[2]
            species = species.split("(")[0]


            if japanese_name != "":
                # 和名付与
                species = japanese_name + ":" + species

            # 新しく書き込む行を作成
            new_row = species + "\t" + comp

            inputFileRowList_withJAname.append(new_row)
    
    return inputFileRowList_withJAname

def duplication_remove(inputFileRowList):
    # 重複排除済み魚種組成リスト
    inputFileRowList_duplicationRemoved = []

    merged_comp_obj = {}

    for i, row in enumerate(inputFileRowList):
        # Headerを追加
        if i == 0:
            inputFileRowList_duplicationRemoved.append(row)
        else:
            row = row.split("\t")
            species = row[0]
            comp = int(row[1].replace("\n",""))

            # 既に魚種組成に存在している場合はマージ
            if species in merged_comp_obj:
                merged_comp_obj[species] = merged_comp_obj[species] + comp
            # 魚種組成に存在していない場合は新規に追加
            else:
                merged_comp_obj[species] = comp
    # 組成量をキーにソート
    merged_comp_list_sorted = sorted(merged_comp_obj.items(), key=lambda x:x[1], reverse=True)

    # 出力リストに追加
    for row in merged_comp_list_sorted:
        new_row = row[0] + "\t" + str(row[1]) + "\n"
        inputFileRowList_duplicationRemoved.append(new_row)

    return inputFileRowList_duplicationRemoved

def minor_remove(inputFileRowList):
    # 1%未満の組成の魚種排除した魚種組成リスト
    inputFileRowList_minorRemoved = []

    # 組成の累計
    total = 0

    # 累計を算出
    for i, row in enumerate(inputFileRowList):
        if i == 0:
            continue
        else:
            row = row.split("\t")
            
            # 種名がない場合の例外処理
            if row[0] == "":
                continue

            try:
                total += int(row[1].replace("\n",""))
            except:
                # 数値変換できない場合の例外処理
                continue

    # 1%未満の組成の魚種排除
    for i, row in enumerate(inputFileRowList):
        if i == 0:
            # Headerを追加
            inputFileRowList_minorRemoved.append(row)
        else:
            comp = int(row.split("\t")[1].replace("\n",""))

            # 1%未満の組成の魚種を除去
            if float(comp) / float(total) < 0.01:
                continue            
            
            inputFileRowList_minorRemoved.append(row)
    
    return inputFileRowList_minorRemoved

def calc_percent(inputFileRowList):
    # 百分率で組成を表示した魚種組成リスト
    inputFileRowList_percent = []

    # 組成の累計
    total = 0

    # 累計を算出
    for i, row in enumerate(inputFileRowList):
        if i == 0:
            continue
        else:
            row = row.split("\t")
            
            # 種名がない場合の例外処理
            if row[0] == "":
                continue

            try:
                total += int(row[1].replace("\n",""))
            except:
                # 数値変換できない場合の例外処理
                continue

    # 100read未満のサンプルは"less than 100 reads"を返す
    if total < 100:
        return "less than 100 reads"
    
    # 魚種組成を百分率で算出
    for i, row in enumerate(inputFileRowList):
        if i == 0:
            # Headerを追加
            inputFileRowList_percent.append(row)
        else:
            species = row.split("\t")[0]
            comp = int(row.split("\t")[1].replace("\n",""))
            comp = round(float(comp) / float(total),4) * 100
            new_row = species + "\t" + str(comp) + "\n"
            inputFileRowList_percent.append(new_row)
    
    return inputFileRowList_percent

def write_inputfile(inputFileRowList):
    # 書き込み先のinputファイルを書き込みモードで開く
    outputFile = open(outputFilePath, "wb")

    # 各行を書き込み
    for row in inputFileRowList:
        outputFile.write(row.encode('utf-8'))

    outputFile.close()

if __name__ == "__main__":
    main()

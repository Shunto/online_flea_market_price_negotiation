import sys, getopt
#import numpy as np
import csv
import time
from modules import csv_io

start_time = time.time()

def usage():
    print("NAME: filtering_listing_data.py -- ")
    print("USAGE: python3 filtering_listing_data.py <anon_item_id>")
    print("-h --help - show the usage of filtering_listing_data.py")
    print("")
    print("EXAMPLES: ")
    print("python3 filtering_listing_data.py 10611035")
    print("")
    sys.exit(2)
    
def main():
    global anon_item_id
    
    try:
        opts, args = getopt.getopt(sys.argv[1:], "h", ["help", "id"])
        anon_item_id = int(args[0])
    except:
        usage()

    for opt, arg in opts:
        if opt == "-h":
            usage()

    listings_fieldnames = []
    listing_threads_fieldnames = []
    filtered_listings = []
    filtered_listing_threads = []

    # filtering listing data
    try:

        # loading listing data (anon_bo_lists_tmp.csv)
        filtering_listing_data_start_time = time.time()
        with open("../ebay_best_offer_bargaining_data/anon_bo_lists.csv", mode='r') as data_set:
            csv_reader = csv.reader(data_set)
            line_count = 0
            # the count of rows to load
            #max_rows_count = 100000
            for row in csv_reader:
                print(row)                
                #filtering_flag = False
                #if line_count == max_rows_count:
                #    break
                if line_count == 0:
                    listings_fieldnames = row
                    line_count += 1
                    continue
                # filtering items whose anon_product_ids are unique
                # removing an item whose anon_product_id is the same as that of the newly loaded one
                #if len(filtered_listings) != 0:
                #    for idx, filtered_item in enumerate(filtered_listings):
                #        if filtered_item[2] == row[2]:
                #            filtered_listings.pop(idx)
                #            filtering_flag = True
                #            break
                #if not filtering_flag:
                #    filtered_listings.append(row)

                    
                #if int(row[0]) == anon_item_id:
                #    listings.append(row)
                
                # filtering items with anon_product_id missing
                if int(row[2]) == 547957:
                    print(row)
                    filtered_listings.append(row)

                # filtering items with no reference prices
                #if row[15] == "" and row[17] == "" and row[19] == "" and row[34] == "":
                #    print(row)
                #    filtered_listings.append(row)
                line_count += 1
    except Exception as ex:
        print(ex)
        
    filtering_time = time.time() - filtering_listing_data_start_time
    with open("result.txt", mode='w') as result:
        print("filtering listing data completed, it took {:f} seconds".format(time.time() - filtering_listing_data_start_time))
        print("total time: {:f} seconds".format(time.time() - start_time))
        result.write("filtering listing data completed, it took " + str(time.time() - filtering_listing_data_start_time) + " seconds\n")

    # filtering listing thread data (anon_bo_threads.csv)
    try:
        # loading listing thread data (anon_bo_threads.csv)
        filtering_listing_threads_data_start_time = time.time()
        with open("../ebay_best_offer_bargaining_data/anon_bo_threads.csv", mode='r') as data_set:
            csv_reader = csv.reader(data_set)
            line_count = 0
            max_rows_count = 0
            for row in csv_reader:
                if line_count == max_rows_count:
                    break
                if line_count == 0:
                    line_count += 1
                    listing_threads_fieldnames = row
                    continue
                print(row)
                # filtering threads connected to filtered listing items by anon_item_id
                for filtered_item in filtered_listings:
                    if int(filtered_item[0]) == int(row[0]):
                        filtered_listing_threads.append(row)
                        break
                #if int(row[0]) == anon_item_id:
                #    listings.append(row)
                line_count += 1
    except Exception as ex:
        print(ex)
    
    with open("filtered_result.txt", mode='a') as result:
        print("filtering listing threads data completed, it took {:f} seconds".format(time.time() - filtering_listing_threads_data_start_time))
        print("total time: {:f} seconds".format(time.time() - start_time))
        result.write("filtering listing thread data completed, it took " + str(time.time() - filtering_listing_threads_data_start_time) + " seconds\n")
        result.write("filtering both listing data and listing thread data completed, it took " + str(time.time() - start_time) + " seconds in total\n")
        print(len(filtered_listings))
        print(len(filtered_listing_threads))
        result.write(str(len(filtered_listings)))
        result.write("\n")
        result.write(str(len(filtered_listing_threads)))
        result.write("\n")

    csv_io.writeToCsv("../ebay_best_offer_bargaining_data/filtered_anon_bo_lists_1.csv", listings_fieldnames, filtered_listings)
    csv_io.writeToCsv("../ebay_best_offer_bargaining_data/filtered_anon_bo_threads_1.csv", listing_threads_fieldnames, filtered_listing_threads)    
    
if __name__ == "__main__":

    main()

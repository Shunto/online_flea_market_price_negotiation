import sys, getopt
#import numpy as np
import csv
import time
from modules import csv_io

start_time = time.time()

def usage():
    print("NAME: get_listing_data.py -- ")
    print("USAGE: python3 get_listing_data.py <anon_item_id>")
    print("-h --help - show the usage of get_listing_data.py")
    print("")
    print("EXAMPLES: ")
    print("python3 get_listing_data.py 10611035")
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

    listings = []
    print("test loading listing data completed, it took {:f} seconds".format(time.time() - start_time))
    try:
        loading_listing_data_start_time = time.time()
        with open("../ebay_best_offer_bargaining_data/anon_bo_lists.csv", mode='r') as data_set:
            csv_reader = csv.reader(data_set)
            line_count = 0
            #max_rows_count = 10000000
            for row in csv_reader:
                if line_count == 0:
                    line_count += 1
                    continue
                #if line_count == max_rows_count:
                #    break
                print(row)
                if int(row[0]) == anon_item_id:
                    listings.append(row)
            
                #data.append(row)
                line_count += 1
    except Exception as ex:
        print(ex)
            
    # loading listing data (anon_bo_lists_tmp.csv)
    #all_listings = np.genfromtxt("../ebay_best_offer_bargaining_data/anon_bo_lists.csv", delimiter=",")
    #all_listings = np.genfromtxt("../ebay_best_offer_bargaining_data/anon_bo_lists_tmp.csv", delimiter=",")
    #loading_time = time.time() - loading_listing_data_start_time
    #with open("result.txt", mode='w') as result:
        #print("loading listing data completed, it took {:f} seconds".format(time.time() - loading_listing_data_start_time))
        #result.write("loading listing data completed, it took" + str(time.time() - loading_listing_data_start_time) + "seconds")
        #print("total time: {:f}".format(time.time() - start_time))
    #all_listings = np.genfromtxt("../ebay_best_offer_bargaining_data/anon_bo_lists_tmp_2.csv", delimiter=",")
    
    # loading listing thread data (anon_bo_threads.csv)
    #all_listing_threads = np.genfromtxt("../ebay_best_offer_bargaining_data/anon_bo_threads.csv", delimiter=",")
    #all_listing_threads = np.genfromtxt("../ebay_best_offer_bargaining_data/anon_bo_threads_tmp.csv", delimiter=",")
    try:
        loading_listing_threads_data_start_time = time.time()
        with open("../ebay_best_offer_bargaining_data/anon_bo_threads.csv", mode='r') as data_set:
            csv_reader = csv.reader(data_set)
            line_count = 0
            max_rows_count = 0
            for row in csv_reader:
                if line_count == max_rows_count:
                    break
                if line_count == 0:
                    line_count += 1
                    continue
                print(row)
                if int(row[0]) == anon_item_id:
                    listings.append(row)
            
                #data.append(row)
                line_count += 1
    except Exception as ex:
        print(ex)

    print("loading listing threads data completed, it took {:f} seconds".format(time.time() - loading_listing_threads_data_start_time))
    print("total time: {:f}".format(time.time() - start_time))
    #all_listing_threads = np.genfromtxt("../ebay_best_offer_bargaining_data/anon_bo_threads_tmp_2.csv", delimiter=",")
    #print(all_listing_threads[0:10])

    # saving to listings the listings corresponding to the anon_item_id
    #searching_listing_threads_data_start_time = time.time()
    #listings = all_listings[all_listings[:, 0] == anon_item_id]
    #print("searching listing data for the specified item id completed, it took {:f} seconds".format(time.time() - searching_listing_threads_data_start_time))
    #print("total time: {:f}".format(time.time() - start_time))

    # saving to listing_threads the threads corresponding to the anon_item_id
    #searching_listing_threads_data_start_time = time.time()
    #listing_threads = all_listing_threads[all_listing_threads[:, 0] == anon_item_id]
    #print("searching listing threads data for the specified item id completed, it took {:f} seconds".format(time.time() - searching_listing_threads_data_start_time))
    #print("total time: {:f}".format(time.time() - start_time))
    with open("threads_result.txt", mode='w') as result:
        result.write("loading listing data completed, it took" + str(time.time() - loading_listing_threads_data_start_time) + "seconds\n")
        print(len(listings))
        result.write(str(len(listings)))
        result.write("\n")
        #print(listing_threads.shape)
        #print("total time: {:f}".format(time.time() - start_time))
    

    #all_listings = readFromCsv("../ebay_best_offer_bargaining_data/anon_bo_lists_tmp_2.csv")
    #listings_fieldnames = all_listings[0]
    #print(listings_fieldnames)
    #all_listing_threads = readFromCsv("../ebay_best_offer_bargaining_data/anon_bo_threads_tmp_2.csv")
    #listing_threads_fieldnames = all_listing_threads[0]
    #print(listing_threads_fieldnames)
    #listings = []
    # creating a dummy numpy array to make it possible to cocatanate
    #listing_threads = np.empty([1, all_listing_threads.shape[1]])
    #listing_threads = []
    #for listing in all_listings:
    #    listing_bool = False
    #    anon_item_id = listing['anon_item_id']
        #listing_threads_tmp = all_listing_threads[all_listing_threads[:, 0] == anon_item_id]
    #    for listing_thread in all_listing_threads:
    #        if listing_thread['anon_item_id'] == anon_item_id:
    #            listing_threads.append(listing_thread)
    #           listing_bool= True

    #    if listing_bool:
    #        listings.append(listing)
        
        #if listing_threads_tmp.size != 0:
        #if len(listing_therads_tmp) != 0:
            #print(listing_threads_tmp.shape)
            #print("id: {}, the number of threads: {}".format(anon_item_id, len(listing_threads_tmp)))
            #listings.append(listing)
            #for listing_thread in listing_threads_tmp:
            #    listing_threads.append(listing_thread)

            #listing_threads = np.concatenate((listing_threads, listing_threads_tmp), axis=1)
            #listing_threads.append(listing_threads_tmp)
    
    #print(listings)
    #print(listing_threads)
    #print(listing_threads)
    #for listing in listing_threads:
    #    print(listing)
    
    # removing the dummy numpy array created in the beginning
    #listing_threads = listing_threads[:,1:]
    
    #writeToCsv("../ebay_best_offer_bargaining_data/anon_bo_lists_tmp_3.csv", listings_fieldnames, listinlgs)
    #writeToCsv("../ebay_best_offer_bargaining_data/anon_bo_threads_tmp_3.csv", listing_threads_fieldnames, listing_threads)        
    
if __name__ == "__main__":

    main()

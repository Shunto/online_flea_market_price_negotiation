import sys, getopt
import numpy as np
import csv

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

    # loading listing data (anon_bo_lists_tmp.csv)
    # all_listings = np.genfromtxt("../ebay_best_offer_bargaining_data/anon_bo_lists_tmp.csv", delimiter=",")
    all_listings = np.genfromtxt("../ebay_best_offer_bargaining_data/anon_bo_lists_tmp_2.csv", delimiter=",")
    
    # loading listing thread data (anon_bo_threads.csv)
    #all_listing_threads = np.genfromtxt("../ebay_best_offer_bargaining_data/anon_bo_threads_tmp.csv", delimiter=",")
    all_listing_threads = np.genfromtxt("../ebay_best_offer_bargaining_data/anon_bo_threads_tmp_2.csv", delimiter=",")
    #print(all_listing_threads[0:10])

    # saving to listings the listings corresponding to the anon_item_id
    #listings = all_listings[all_listings[:, 0] == anon_item_id]
    
    # saving to listing_threads the threads corresponding to the anon_item_id
    #listing_threads = all_listing_threads[all_listing_threads[:, 0] == anon_item_id]
    print(all_listings.shape)
    print(all_listing_threads.shape)

    all_listings_tmp = readFromCsv("../ebay_best_offer_bargaining_data/anon_bo_lists_tmp_2.csv")
    print(all_listings_tmp)
    listings_fieldnames = all_listings_tmp[0]
    print(listings_fieldnames)
    all_listing_threads_tmp = readFromCsv("../ebay_best_offer_bargaining_data/anon_bo_threads_tmp_2.csv")
    listing_threads_fieldnames = all_listing_threads_tmp[0]
    print(listing_threads_fieldnames)
    listings = []
    # creating a dummy numpy array to make it possible to cocatanate
    #listing_threads = np.empty([1, all_listing_threads.shape[1]])
    listing_threads = []
    for listing in all_listings:
        anon_item_id = listing[0]
        listing_threads_tmp = all_listing_threads[all_listing_threads[:, 0] == anon_item_id]
        if listing_threads_tmp.size != 0:
            #print(listing_threads_tmp.shape)
            print("id: {}, the number of threads: {}".format(anon_item_id, listing_threads_tmp.shape))
            listings.append(listing)
            for listing_thread in listing_threads_tmp:
                listing_threads.append(listing_thread)

            #listing_threads = np.concatenate((listing_threads, listing_threads_tmp), axis=1)
            #listing_threads.append(listing_threads_tmp)
    
    #print(listings)
    #print(listing_threads)
    #print(listing_threads)
    #for listing in listing_threads:
    #    print(listing)
    
    # removing the dummy numpy array created in the beginning
    #listing_threads = listing_threads[:,1:]
    
    writeToCsv("../ebay_best_offer_bargaining_data/anon_bo_lists_tmp_3.csv", listings_fieldnames, listings)
    writeToCsv("../ebay_best_offer_bargaining_data/anon_bo_threads_tmp_3.csv", listing_threads_fieldnames, listing_threads)

def writeToCsv(filename, fieldnames, data_list):
    with open(filename, mode='w') as data:
        data_writer = csv.writer(data, delimiter=',', quotechar='"', quoting=csv.QUOTE_MINIMAL)
        writer = csv.DictWriter(data, fieldnames=fieldnames)

        writer.writeheader()
        for entry in data_list:
            data_writer.writerow(entry)

def readFromCsv(filepath):
    data = []
    with open(filepath, mode='r') as data_set:
        csv_reader = csv.DictReader(data_set)
        line_count = 0
        for row in csv_reader:
            if line_count == 0:
                line_count += 1
            data.append(row)
            line_count += 1
    return data
        
    
if __name__ == "__main__":

    main()

import sys, getopt
import numpy as np

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
    listing_threads = []
    for anon_item_id in all_listings[:, 0]:
        listing_threads_tmp = all_listing_threads[all_listing_threads[:, 0] == anon_item_id]
        if listing_threads_tmp.size != 0:
            #print(listing_threads_tmp.shape)
            print("id: {}, the number of threads: {}".format(anon_item_id, listing_threads_tmp.shape))
            listing_threads.append(listing_threads_tmp)
    
    #print(listings)
    #print(listing_threads)
    #print(listing_threads)
    #for listing in listing_threads:
    #    print(listing)
        
    
if __name__ == "__main__":

    main()
